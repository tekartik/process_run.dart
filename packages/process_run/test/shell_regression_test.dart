@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process_run/cmd_run.dart' show runCmd;
import 'package:process_run/shell.dart';
// ignore: deprecated_member_use_from_same_package
import 'package:process_run/src/dev_cmd_run.dart' show devRunCmd;
import 'package:process_run/src/io/shared_stdin.dart' show SharedStdIn;
import 'package:process_run/src/user_config.dart';
import 'package:test/test.dart';

import 'shell_test.dart' show echoExe, echoExeAbsolutePath, ensureEchoExe;

/// Lines written to a shell stdout sink.
Future<List<String>> _captureLines(
  Future<void> Function(StreamSink<List<int>> sink) action,
) async {
  var controller = ShellLinesController();
  var lines = <String>[];
  var done = controller.stream.forEach(lines.add);
  await action(controller.sink);
  controller.close();
  await done;
  return lines;
}

void main() {
  group('shell_regression', () {
    setUpAll(() async {
      await ensureEchoExe();
    });

    test('pipe', () async {
      // The stdin of the second command is the output of the first one,
      // ended so that a command reading until the end completes.
      var results = await Shell(
        verbose: false,
      ).run('$echoExe -o hello').pipe('$echoExe -i');
      expect(results.outText, 'hello');
    });

    test('pipe cat', () async {
      var results = await Shell(verbose: false).run('echo hello').pipe('cat');
      expect(results.outText, 'hello');
    }, skip: Platform.isWindows ? 'no cat on Windows' : null);

    test('ShellProcessResults.shell', () async {
      var shell = Shell(verbose: false);
      var results = await shell.runScript('$echoExe -o a');
      expect(results.shell, same(shell));
    });

    test('runExecutableArguments onProcess', () async {
      var count = 0;
      await runExecutableArguments(echoExeAbsolutePath, [
        '-o',
        'a',
      ], onProcess: (_) => count++);
      expect(count, 1);
      count = 0;
      await Shell(verbose: false).runExecutableArguments(echoExeAbsolutePath, [
        '-o',
        'a',
      ], onProcess: (_) => count++);
      expect(count, 1);
    });

    test('runExecutableArgumentsSync throwOnError', () {
      expect(
        () => runExecutableArgumentsSync(echoExeAbsolutePath, [
          '-x',
          '1',
        ], throwOnError: true),
        throwsA(isA<ShellException>()),
      );
      // Compat: does not throw by default
      expect(
        runExecutableArgumentsSync(echoExeAbsolutePath, ['-x', '1']).exitCode,
        1,
      );
    });

    test('sync aliases applied once', () async {
      // echo is not found (no PATH) and run in a shell, its alias must not be
      // applied again on the resolved command.
      var environment = ShellEnvironment.empty()..aliases['echo'] = 'echo AA';
      // Windows cannot start a process (cmd.exe) with a fully empty environment
      // (The parameter is incorrect).
      if (Platform.isWindows) {
        environment.vars['SystemRoot'] = Platform.environment['SystemRoot']!;
      }
      var shell = Shell(
        environment: environment,
        includeParentEnvironment: false,
        runInShell: true,
        verbose: false,
      );
      expect((await shell.run('echo hi')).outText.trim(), 'AA hi');
      expect(shell.runSync('echo hi').outText.trim(), 'AA hi');
    });

    test('cd keeps includeParentEnvironment false', () {
      var shell = Shell(
        environment: {'TK_ONLY': '1'},
        includeParentEnvironment: false,
        verbose: false,
      );
      expect(shell.options.environment.keys, ['TK_ONLY']);
      var path = Directory.systemTemp.path;
      expect(shell.cd(path).options.environment.keys, ['TK_ONLY']);
      expect(shell.pushd(path).options.environment.keys, ['TK_ONLY']);
      expect(
        shell.cloneWithOptions(shell.options.clone()).options.environment.keys,
        ['TK_ONLY'],
      );
      // The parent environment is still there by default
      var defaultShell = Shell(verbose: false);
      expect(
        defaultShell.cd(path).options.environment.keys,
        containsAll(defaultShell.options.environment.keys),
      );
    });

    test('ShellEnvironment ==', () {
      var env1 = ShellEnvironment.empty()
        ..vars['A'] = '1'
        ..aliases['a'] = 'echo a';
      var env2 = ShellEnvironment.empty()
        ..vars['A'] = '1'
        ..aliases['a'] = 'echo a';
      // == itself (the map matchers compare the content only)
      expect(env1 == env1, isTrue);
      expect(env1 == env2, isTrue);
      expect(env1.aliases == env2.aliases, isTrue);
      env2.aliases['a'] = 'echo b';
      expect(env1 == env2, isFalse);
      expect(env1.aliases == env2.aliases, isFalse);
    });

    test('userLoadEnv keeps aliases', () {
      var previous = userConfig;
      try {
        userConfig = UserConfig(aliases: {'tk_a1': 'echo a1'});
        userLoadEnv(vars: {'TK_V1': '1'});
        expect(userConfig.aliases, {'tk_a1': 'echo a1'});
        userLoadEnv(aliases: {'tk_a2': 'echo a2'});
        expect(userConfig.aliases, {'tk_a1': 'echo a1', 'tk_a2': 'echo a2'});
        expect(userConfig.vars['TK_V1'], '1');
      } finally {
        userConfig = previous;
      }
    });

    test('runCmd mode', () async {
      var result = await runCmd(
        ProcessCmd(echoExeAbsolutePath, [
          '-o',
          'runCmd mode',
        ], mode: ProcessStartMode.inheritStdio),
      );
      // Not captured with the inherited stdio
      expect(result.stdout, isNull);
    });

    test('devRunCmd stdout', () async {
      var lines = await _captureLines((sink) async {
        // ignore: deprecated_member_use_from_same_package
        await devRunCmd(
          ProcessCmd(echoExeAbsolutePath, ['-o', 'dev_out']),
          stdout: sink,
        );
      });
      expect(lines, contains('dev_out'));
    });

    test('popd and comments use the shell stdout', () async {
      var lines = await _captureLines((sink) async {
        var shell = Shell(stdout: sink, commentVerbose: true);
        shell.pushd(Directory.systemTemp.path).popd();
        await shell.run('# a comment');
      });
      expect(lines, contains('\$ cd ${Directory.current.path}'));
      expect(lines, contains('# a comment'));
    });

    test('kill while starting, then a new run', () async {
      var shell = Shell(verbose: false);
      int? pid;
      var first = shell.run(
        '$echoExe --wait 5000',
        onProcess: (process) => pid = process.pid,
      );
      // Process.start in flight
      for (var i = 0; i < 10; i++) {
        await Future<void>.microtask(() {});
      }
      expect(pid, isNull);
      shell.kill();
      // The restart pattern: the killed command used to keep running.
      var second = shell.run('$echoExe -o second');
      await expectLater(first, throwsA(isA<ShellException>()));
      expect((await second).outText, 'second');
      var stopwatch = Stopwatch()..start();
      while (pid == null && stopwatch.elapsed < const Duration(seconds: 10)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      var running = true;
      while (running && stopwatch.elapsed < const Duration(seconds: 3)) {
        running = await ShellProcesses.isRunning(pid!);
        if (running) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
      expect(running, isFalse);
    });

    test('output without encoding as bytes', () async {
      var shell = Shell(
        options: ShellOptions(stdoutEncoding: null, verbose: false),
      );
      var results = await shell.runScript('$echoExe -o hello');
      expect(results.first.stdout, isNot(isA<String>()));
      expect(utf8.decode(results.stdoutAsUint8List).trim(), 'hello');
      var piped = await shell.run('$echoExe -o hello').pipe('$echoExe -i');
      expect(piped.outText, 'hello');
    });

    test('shellStreamLines listener pausing', () async {
      var controller = StreamController<List<int>>();
      var lines = <String>[];
      var done = () async {
        // await for pauses the subscription while the body runs
        await for (var line in shellStreamLines(controller.stream)) {
          lines.add(line);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      }();
      controller.add(utf8.encode('a\n'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      controller.add(utf8.encode('b\nc'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      controller.add(utf8.encode('d\n'));
      await controller.close();
      await done;
      // Each line once
      expect(lines, ['a', 'b', 'cd']);
    });

    test('sharedStdIn end of input', () async {
      var stdin = SharedStdIn(Stream.fromIterable([utf8.encode('a\n')]));
      expect(
        await stdin.lines().toList().timeout(const Duration(seconds: 10)),
        ['a'],
      );
      // Later listeners are done at once
      expect(
        await stdin.lines().toList().timeout(const Duration(seconds: 10)),
        isEmpty,
      );
      await stdin.terminate();

      // The command reading its input until the end gets it.
      stdin = SharedStdIn(Stream.fromIterable([utf8.encode('hello')]));
      var results = await Shell(
        stdin: stdin,
        verbose: false,
      ).run('$echoExe -i').timeout(const Duration(seconds: 10));
      expect(results.outText, 'hello');
      await stdin.terminate();
    });

    test('sharedStdIn terminate with input nobody read', () async {
      var controller = StreamController<List<int>>();
      var stdin = SharedStdIn(controller.stream);
      await stdin.listen((_) {}).cancel();
      // Typed once the command exited
      controller.add(utf8.encode('typed\n'));
      await Future<void>.delayed(Duration.zero);
      await stdin.terminate().timeout(const Duration(seconds: 10));
      await controller.close();
    });
  });
}
