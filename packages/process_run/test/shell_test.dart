// ignore_for_file: avoid_print

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

import 'package:process_run/shell.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/dartbin_cmd.dart'
    show parseDartBinVersionOutput;
import 'package:process_run/src/utils/hex_utils.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'shell_test_common.dart';

// Compiled version of echo.dart
var echoExePath = join('.local', 'example', 'echo.exe');
var echoExeAbsolutePath = normalize(absolute(echoExePath));
var echoExe = shellArgument(echoExePath);
Future<void> ensureEchoExe() async {
  if (!File(echoExe).existsSync()) {
    await Directory(dirname(echoExePath)).create(recursive: true);
    await run(
      'dart compile exe ${shellArgument(join('example', 'echo.dart'))} -o $echoExe',
    );
  }
}

@Deprecated('Dev only, used when uncommenting debug = devTrue')
bool devTrue = true;

// bool debug = devTrue;
bool debug = false;

// To set in both variable for a full empty environment
var dummyEnvPath = join('test', 'data', 'test_env.yaml_dummy');

ShellEnvironment newEnvNoOverride() => ShellEnvironment(
  environment: <String, String>{
    userEnvFilePathEnvKey: dummyEnvPath,
    localEnvFilePathEnvKey: dummyEnvPath,
  },
);

void main() {
  group('Shell', () {
    test('public', () {
      // ignore: unnecessary_statements
      getFlutterBinVersion;
      // ignore: unnecessary_statements
      getFlutterBinChannel;
      isFlutterSupported;
      isFlutterSupportedSync;
      dartVersion;
      dartChannel;
      // ignore: unnecessary_statements
      dartChannelStable;
      // ignore: unnecessary_statements
      dartChannelBeta;
      // ignore: unnecessary_statements
      dartChannelDev;
      // ignore: unnecessary_statements
      dartChannelMaster;

      // ignore: unnecessary_statements
      promptConfirm;
      // ignore: unnecessary_statements
      prompt;
      // ignore: unnecessary_statements
      promptTerminate;

      // ignore: unnecessary_statements
      ShellException;
      // ignore: unnecessary_statements
      ShellLinesController;
      // ignore: unnecessary_statements
      which;
      // ignore: unnecessary_statements
      whichSync;
      // ignore: unnecessary_cast
      (null as Process?)?.errLines;
      // ignore: unnecessary_cast
      (null as List<ProcessResult>?)?.outText;
      // ignore: unnecessary_cast
      (null as List<ProcessResult>?)?.outLines;
      // ignore: unnecessary_cast
      (null as List<ProcessResult>?)?.errText;
      // ignore: unnecessary_cast
      (null as List<ProcessResult>?)?.errLines;
    });

    test('arguments', () async {
      await ensureEchoExe();
      var shell = Shell(verbose: debug);
      var text = 'Hello  world';
      var results = await shell.run('''
# this will print 'Helloworld'
$echoExe -o Hello  world
$echoExe -o $text
# this will print 'Hello  world'
$echoExe -o 'Hello  world'
$echoExe -o 'Hello  world'
$echoExe -o ${shellArgument(text)}
$echoExe -o 你好
$echoExe -o éà
''');
      expect(results[0].stdout.toString().trim(), 'Helloworld');
      expect(results[1].stdout.toString().trim(), 'Helloworld');
      expect(results[2].stdout.toString().trim(), 'Hello  world');
      expect(results[3].stdout.toString().trim(), 'Hello  world');
      expect(results[4].stdout.toString().trim(), 'Hello  world');
      if (Platform.isWindows) {
        // Not supported requires utf8 encoding (see test below)
      } else {
        expect(results[5].stdout.toString().trim(), '你好');
        expect(results[6].stdout.toString().trim(), 'éà');
      }
      expect(results.length, 7);
    });

    test('noStdoutResult/noStderrResult', () async {
      await ensureEchoExe();
      var options = ShellOptions(noStdoutResult: true, verbose: false);
      var shell = Shell(options: options);
      var script = '$echoExe -o Out -e Err';
      var result = (await shell.run(script)).first;
      expect(result.stdout, isNull);
      expect(result.stderr, 'Err');
      result = (await shell.runExecutableArguments(echoExe, [
        '-o',
        'Out',
        '-e',
        'Err',
      ]));
      expect(result.stdout, isNull);
      expect(result.stderr, 'Err');
      // Not valid for runSync
      result = (shell.runSync(script)).first;
      expect(result.stdout, 'Out');
      expect(result.stderr, 'Err');
      // Not valid for runExecutableArgumentsSync
      result = (shell.runExecutableArgumentsSync(echoExe, [
        '-o',
        'Out',
        '-e',
        'Err',
      ]));
      expect(result.stdout, 'Out');
      expect(result.stderr, 'Err');
      result = (await run(script, options: options)).first;
      expect(result.stdout, isNull);
      expect(result.stderr, 'Err');
      result = (await runExecutableArguments(echoExe, [
        '-o',
        'Out',
        '-e',
        'Err',
      ], noStdoutResult: true));
      expect(result.stdout, isNull);
      expect(result.stderr, 'Err');
      // Not valid for runSync
      result = (runSync(script, options: options)).first;

      expect(result.stdout, 'Out');
      expect(result.stderr, 'Err');
      options = ShellOptions(noStderrResult: true, verbose: false);
      shell = Shell(options: options);
      result = (await shell.run(script)).first;
      expect(result.stdout, 'Out');
      expect(result.stderr, isNull);
      result = (await run(script, options: options)).first;
      expect(result.stdout, 'Out');
      expect(result.stderr, isNull);
    });

    test('arguments utf8', () async {
      await ensureEchoExe();
      var shell = Shell(verbose: debug, stdoutEncoding: utf8);
      var results = await shell.run('''
$echoExe -o 你好
''');
      expect(results.outLines.toList()[0], '你好');
      expect(results.length, 1);
    });

    test('outLines, errLines', () async {
      await ensureEchoExe();
      var shell = Shell(verbose: debug, runInShell: true);

      var results = await shell.run(
        '$echoExe --stdout-hex ${bytesToHex(utf8.encode('Hello\nWorld'))}',
      );
      expect(results.outLines, ['Hello', 'World']);
      expect(results[0].outLines, ['Hello', 'World']);
      expect(results.errLines, isEmpty);

      results = await shell.run('$echoExe -e Hello');
      expect(results.outLines, isEmpty);
      expect(results.errLines, ['Hello']);

      results = await shell.run('''
# This is a 2 commands file

$echoExe -o Hello

$echoExe -e World
''');
      expect(results.outLines, ['Hello']);
      expect(results.errLines, ['World']);
    });

    test('backslash', () async {
      await ensureEchoExe();
      var shell = Shell(verbose: debug);
      var weirdText = r'a/\b c/\d';
      var results = await shell.run('''
$echoExe -o $weirdText
$echoExe -o ${shellArgument(weirdText)}

''');

      if (Platform.isWindows) {
        expect(results[0].stdout.toString().trim(), r'a/\bc/\d');
        expect(results[1].stdout.toString().trim(), r'a/\b c/\d');
      } else {
        expect(results[0].stdout.toString().trim(), r'a/bc/d');
        expect(results[1].stdout.toString().trim(), r'a/\b c/\d');
      }
      expect(results.length, 2);
    });
    test('dart', () async {
      var shell = Shell(verbose: debug);
      var results = await shell.run('''dart --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });
    test('sync dart', () async {
      var shell = Shell(verbose: debug);
      var results = shell.runSync('''dart --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('dart runExecutableArguments', () async {
      var shell = Shell(verbose: debug);
      var result = await shell.runExecutableArguments('dart', ['--version']);
      expect(result.exitCode, 0);
    });
    test('dart runExecutableArguments bad arg', () async {
      var shell = Shell(verbose: debug);
      try {
        await shell.runExecutableArguments('dart', ['--bad-arg']);
        fail('shoud fail');
      } on ShellException catch (e) {
        try {
          // dart <3.10
          expect(e.result!.exitCode, 255);
        } catch (_) {
          // dart >= 3.10
          expect(e.result!.exitCode, 64);
        }
      }
    });

    test('kill simple', () async {
      try {
        await () async {
          await ensureEchoExe();
          var shell = Shell();
          await shell.run('$echoExe --version');
          late Future future;
          try {
            future = shell.run('$echoExe --wait 30000');
            await future.timeout(const Duration(milliseconds: 2500));
            fail('should fail');
          } on TimeoutException catch (_) {
            // 1: TimeoutException after 0:00:02.000000: Future not completed
            //devPrint('1: $e');
          }
          try {
            shell.kill();
            await future;
            fail('should fail');
          } on ShellException catch (_) {
            // 2: ShellException(dart echo.dart --wait 3000, exitCode -15, workingDirectory:
            // devPrint('2: $_');
          }
        }().timeout(const Duration(seconds: 30));
      } on TimeoutException catch (e) {
        stderr.writeln('TimeOutException $e');
        stderr.writeln('Allowed: could happen on CI');
      }
    }, timeout: const Timeout(Duration(seconds: 50)));

    test('kill SIGKILL', () async {
      try {
        await () async {
          await ensureEchoExe();
          var shell = Shell();
          await shell.run('$echoExe --version');
          late Future future;
          try {
            future = shell.run('$echoExe --wait 30000');
          } on TimeoutException catch (_) {}
          try {
            shell.kill(ProcessSignal.sigkill);
            await future;
            fail('should fail');
          } on ShellException catch (_) {
            // 2: ShellException(dart echo.dart --wait 3000, exitCode -15, workingDirectory:
          }
        }().timeout(const Duration(seconds: 30));
      } on TimeoutException catch (e) {
        stderr.writeln('TimeOutException $e');
        stderr.writeln('Allowed: could happen on CI');
      }
    }, timeout: const Timeout(Duration(seconds: 50)));
    test('kill message only when verbose', () async {
      await ensureEchoExe();
      for (var verbose in [false, true]) {
        var out = StreamController<List<int>>();
        var err = StreamController<List<int>>();
        var outDone = out.stream.drain<void>();
        var errText = err.stream.transform(utf8.decoder).join();
        var shell = Shell(verbose: verbose, stdout: out.sink, stderr: err.sink);
        var started = Completer<void>();
        var future = shell.run(
          '$echoExe --wait 30000',
          onProcess: (_) => started.complete(),
        );
        await started.future;
        shell.kill();
        await expectLater(future, throwsA(isA<ShellException>()));
        await out.close();
        await err.close();
        await outDone;
        expect((await errText).contains('killing'), verbose);
      }
    }, timeout: const Timeout(Duration(seconds: 50)));
    test('kill complex', () async {
      await ensureEchoExe();
      try {
        await () async {
          var shell = Shell();
          late Future future;
          try {
            future = shell.run('$echoExe --wait 3000');
            await future.timeout(const Duration(milliseconds: 2000));
            fail('should fail');
          } on TimeoutException catch (_) {
            // 1: TimeoutException after 0:00:02.000000: Future not completed
            shell.kill();
            //devPrint('1: $e');
          }
          try {
            await future;
            fail('should fail');
          } on ShellException catch (_) {
            // 2: ShellException($echoExe--wait 3000, exitCode -15, workingDirectory:
            // devPrint('2: $e');
          }

          try {
            var future = shell.run('$echoExe --wait 10000');
            await Future<void>.delayed(const Duration(milliseconds: 3000));
            shell.kill();
            await future.timeout(const Duration(milliseconds: 8000));
            fail('should fail');
          } on ShellException catch (_) {
            // devPrint('3: $e');
          }

          try {
            // Killing before calling
            future = shell
                .run('$echoExe --wait 9000')
                .timeout(const Duration(milliseconds: 7000));
            shell.kill();
            await future;
            fail('should fail');
          } on ShellException catch (_) {
            // devPrint('3: $e');
          }
        }().timeout(const Duration(seconds: 40));
      } on TimeoutException catch (e) {
        stderr.writeln('TimeOutException $e');
        stderr.writeln('Allowed: could happen on CI');
      }
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('stdout sink closed while the command still writes', () async {
      await ensureEchoExe();
      var controller = ShellLinesController();
      var shell = Shell(stdout: controller.sink, verbose: false);
      var started = Completer<void>();
      var future = shell.run(
        '$echoExe --wait 1000 --stdout late',
        onProcess: (_) => started.complete(),
      );
      await started.future;
      // Its owner is done with it: what the command writes next is not sent
      // to it (it threw "Cannot add event after closing", unhandled).
      controller.close();
      var results = await future;
      expect(results.outText, 'late');
    }, timeout: const Timeout(Duration(seconds: 50)));

    test(
      'kill, stdout sink closed, the command still writes',
      () async {
        var controller = ShellLinesController();
        var shell = Shell(stdout: controller.sink, verbose: false);
        var ready = Completer<void>();
        controller.stream.listen((line) {
          if (line == 'ready' && !ready.isCompleted) {
            ready.complete();
          }
        });
        late Process process;
        // Ignores the sigterm of the kill (what it starts too) and keeps
        // writing for 2 seconds.
        var script =
            "trap '' TERM; echo ready; i=0; "
            r'while [ $i -lt 20 ]; do sleep 0.1; echo late; i=$((i+1)); done';
        var future = shell.runExecutableArguments('sh', [
          '-c',
          script,
        ], onProcess: (started) => process = started);
        await ready.future;
        expect(shell.kill(), isTrue);
        await expectLater(future, throwsA(isA<ShellException>()));
        controller.close();
        // It ends having written to a closed sink: nothing is thrown.
        await process.exitCode;
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      testOn: '!windows',
      timeout: const Timeout(Duration(seconds: 50)),
    );

    test(
      'killed by the pid of onProcess: the run ends with its exit code',
      () async {
        await ensureEchoExe();
        var shell = Shell(verbose: false, throwOnError: false);
        var started = Completer<Process>();
        var future = shell.runExecutableArguments(echoExeAbsolutePath, [
          '--wait',
          '30000',
        ], onProcess: started.complete);
        var process = await started.future;
        // The process and what it started, until they exited.
        expect(await ShellProcesses.kill([process.pid], tree: true), isEmpty);
        // Not a kill of the shell: the run ends as the command does.
        var result = await future;
        expect(result.exitCode, isNot(0));
        expect(result.exitCode, await process.exitCode);
      },
      timeout: const Timeout(Duration(seconds: 50)),
    );

    test('no input: stdin ended at once', () async {
      await ensureEchoExe();
      // As `Process.run` does: a command reading its input gets the end of
      // it (it waits for it without `stdin:`).
      var result = await Shell(
        stdin: const Stream<List<int>>.empty(),
        verbose: false,
      ).runExecutableArguments(echoExeAbsolutePath, ['--stdin', '-o', 'done']);
      expect(result.stdout, 'done');
    }, timeout: const Timeout(Duration(seconds: 50)));

    test('inheritStdio: a stdin given is ignored', () async {
      await ensureEchoExe();
      // The process has the terminal, no pipe to feed (it threw, unhandled,
      // at the first data).
      var result = await Shell(
        options: ShellOptions(
          mode: ProcessStartMode.inheritStdio,
          stdin: Stream.value(utf8.encode('ignored\n')),
          verbose: false,
        ),
      ).runExecutableArguments(echoExeAbsolutePath, ['--wait', '300']);
      expect(result.exitCode, 0);
      expect(result.stdout, isNull);
    }, timeout: const Timeout(Duration(seconds: 50)));

    group('detached', () {
      test('detached: the run ends once the command started', () async {
        await ensureEchoExe();
        var shell = Shell(
          options: ShellOptions(
            mode: ProcessStartMode.detached,
            verbose: false,
          ),
        );
        Process? process;
        var result = await shell
            .runExecutableArguments(echoExeAbsolutePath, [
              '--wait',
              '30000',
            ], onProcess: (started) => process = started)
            .timeout(const Duration(seconds: 15));
        addTearDown(() => ShellProcesses.kill([result.pid]));
        expect(result.pid, process!.pid);
        // No exit code, nothing read.
        expect(result.exitCode, 0);
        expect(result.stdout, isNull);
        expect(result.stderr, isNull);
        expect(await ShellProcesses.isRunning(result.pid), isTrue);
        // No longer a command of the shell: its kill leaves it.
        expect(shell.kill(), isFalse);
        expect(await ShellProcesses.isRunning(result.pid), isTrue);
        expect(await ShellProcesses.kill([result.pid]), isEmpty);
        expect(await ShellProcesses.isRunning(result.pid), isFalse);
      }, timeout: const Timeout(Duration(seconds: 50)));

      test('detached: global runExecutableArguments', () async {
        await ensureEchoExe();
        var result = await runExecutableArguments(
          echoExeAbsolutePath,
          ['--wait', '30000'],
          mode: ProcessStartMode.detached,
        ).timeout(const Duration(seconds: 15));
        addTearDown(() => ShellProcesses.kill([result.pid]));
        expect(result.exitCode, 0);
        expect(await ShellProcesses.isRunning(result.pid), isTrue);
        expect(await ShellProcesses.kill([result.pid]), isEmpty);
      }, timeout: const Timeout(Duration(seconds: 50)));

      test(
        'detachedWithStdio: the streams are the ones of onProcess',
        () async {
          await ensureEchoExe();
          Process? process;
          var result =
              await Shell(
                    options: ShellOptions(
                      mode: ProcessStartMode.detachedWithStdio,
                      verbose: false,
                    ),
                  )
                  .runExecutableArguments(echoExeAbsolutePath, [
                    '--stdin',
                    '--write-line',
                  ], onProcess: (started) => process = started)
                  .timeout(const Duration(seconds: 15));
          addTearDown(() => ShellProcesses.kill([result.pid]));
          expect(result.exitCode, 0);
          expect(result.stdout, isNull);
          // Nothing read by the shell: the caller talks to the process.
          var out = process!.stdout.transform(utf8.decoder).join();
          process!.stderr.drain<void>().ignore();
          process!.stdin.writeln('hello');
          await process!.stdin.flush();
          expect((await out).trim(), 'hello');
        },
        timeout: const Timeout(Duration(seconds: 50)),
      );

      test(
        'detachedWithStdio: a result asked comes with the end of the output',
        () async {
          await ensureEchoExe();
          var result =
              await Shell(
                options: ShellOptions(
                  mode: ProcessStartMode.detachedWithStdio,
                  verbose: false,
                  noStdoutResult: false,
                  noStderrResult: false,
                ),
              ).runExecutableArguments(echoExeAbsolutePath, [
                '--stdout',
                'out',
                '--stderr',
                'err',
                '--exit-code',
                '3',
              ]);
          // A detached process has no exit code.
          expect(result.exitCode, 0);
          expect(result.stdout, 'out');
          expect(result.stderr, 'err');
        },
        timeout: const Timeout(Duration(seconds: 50)),
      );
    });

    group('ShellLinesController', () {
      test('Shell Lines out', () async {
        await ensureEchoExe();
        var linesController = ShellLinesController();
        var shell = Shell(stdout: linesController.sink, verbose: false);
        await shell.run('$echoExe some_text');
        linesController.close();
        expect(await linesController.stream.toList(), ['some_text']);

        linesController = ShellLinesController();
        shell = Shell(stdout: linesController.sink, verbose: false);
        await shell.run('$echoExe some_text1');
        await shell.run('''
      $echoExe some_text2
      $echoExe some_text3
      ''');
        linesController.close();
        expect(await linesController.stream.toList(), [
          'some_text1',
          'some_text2',
          'some_text3',
        ]);
      });
      test('pause', () async {
        await ensureEchoExe();
        late ShellLinesController linesController;
        var lines = <String>[];
        late Shell shell;
        StreamSubscription? subscription;

        void init() {
          lines.clear();
          subscription?.cancel();
          linesController = ShellLinesController();
          shell = Shell(stdout: linesController.sink, verbose: false);
          lines.clear();
          subscription = linesController.stream.listen((event) {
            // devPrint('line: $event');
            lines = [...lines, event];
          });
        }

        init();
        await shell.run('$echoExe some_text');
        expect(lines, ['some_text']);

        init();
        subscription?.pause();
        await shell.run('$echoExe some_text');
        expect(lines, isEmpty);

        init();

        await shell.run('$echoExe some_text1');
        expect(lines, ['some_text1']);
        lines.clear();

        subscription!.pause();
        var count = 0;
        await shell.run(
          '''
      $echoExe some_text2
      $echoExe some_text3
      ''',
          onProcess: (process) {
            count++;
            // devPrint('onProcess ${process.pid} (paused: $paused)');
            process.exitCode.then((exitCode) {
              expect(exitCode, 0);
            });
          },
        );
        expect(count, 2);
        expect(lines, isEmpty);
        lines.clear();
        subscription!.resume();
        await shell.run('''
      $echoExe some_text4
      ''');
        expect(lines.last, 'some_text4');
      });
    });

    test('cd', () async {
      var shell = Shell(verbose: debug);

      var results = await shell.run('dart test/src/$currentDirScriptName.dart');

      expect(results[0].stdout.toString().trim(), Directory.current.path);

      results = await shell.cd('test/src').run('''
dart $currentDirScriptName.dart
''');
      expect(
        results[0].stdout.toString().trim(),
        join(Directory.current.path, 'test', 'src'),
      );
    });

    test('path', () {
      var shell = Shell();
      expect(shell.path, isNotEmpty);
      shell = shell.pushd('test');
      expect(basename(shell.path), 'test');
    });
    test('pushd', () async {
      var shell = Shell(verbose: debug);

      var results = await shell.run('dart test/src/$currentDirScriptName.dart');
      expect(results[0].stdout.toString().trim(), Directory.current.path);

      shell = shell.pushd('test/src');
      results = await shell.run('dart $currentDirScriptName.dart');
      expect(
        results[0].stdout.toString().trim(),
        join(Directory.current.path, 'test', 'src'),
      );

      // pop once
      shell = shell.popd();
      results = await shell.run('dart test/src/$currentDirScriptName.dart');
      expect(results[0].stdout.toString().trim(), Directory.current.path);

      // pop once
      try {
        shell.popd();
        fail('should fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
    });
    test('dart_no_path', () async {
      var environment = Map<String, String>.from(shellEnvironment)
        ..remove('PATH');
      var shell = Shell(environment: environment, verbose: debug);
      var results = await shell.run('''dart --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('pub_no_path', () async {
      // No longer supported
      if (dartVersion < Version(2, 17, 0, pre: '0')) {
        print(userPaths);
        var environment = Map<String, String>.from(shellEnvironment)
          ..remove('PATH');
        var shell = Shell(environment: environment, verbose: false);
        var results = await shell.run('''pub --version''');
        expect(results.length, 1);
        expect(results.first.exitCode, 0);
      }
    });

    test('escape backslash', () async {
      var shell = Shell(verbose: debug);
      var results = await shell.run(r'echo "\\"');
      if (Platform.isWindows) {
        expect(results[0].stdout.toString().trim(), r'\\');
      } else {
        expect(results[0].stdout.toString().trim(), r'\');
      }
    });
    test('others', () async {
      try {
        var shell = Shell(verbose: false, runInShell: Platform.isWindows);
        await shell.run('''
echo Hello world
firebase --version
adb --version
_tekartik_dummy_app_that_does_not_exits
''');
        fail('should fail');
      } on Exception catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
    }); // skip windows for now
  });

  Future testCommand(String command) async {
    var shell = Shell(verbose: debug);
    try {
      await shell.run(command);
    } on ShellException catch (_) {
      // we only accept shell exception here
    }
  }

  test('various command', () async {
    // that can be installed or not
    await testCommand('firebase --version'); // firebase.cmd on windows
    await testCommand('flutter --version'); // flutter.bat on windows
    await testCommand('dart --version'); // dart.exe on windows
    await testCommand(
      '${shellArgument(dartExecutable!)} --version',
    ); // dart.exe on windows
    if (dartVersion < Version(2, 17, 0, pre: '0')) {
      await testCommand('pub --version'); // dart.exe on windows
    }
    // on windows, system command or alias in PowerShell
    await testCommand('echo Hello world');
  });

  test('echo', () async {
    await testCommand('echo Hello world'); // alias to Write-Output
    await testCommand('echo Hello world'); // alias to Write-Output
  });

  test('pipe', () async {
    var dir = join('.dart_tool', 'process_run', 'test');
    await Directory(dir).create(recursive: true);
    var file = File(join(dir, 'echo.output'));
    var shell = Shell();

    // Write to file
    await file.writeAsString(
      (await shell.run('echo Hello world')).first.stdout.toString(),
    );

    // Append to file
    await file.writeAsString(
      (await shell.run('echo Hello world')).first.stdout.toString(),
      mode: FileMode.append,
    );

    try {
      // Update 2024-11-17 Windows used to have different separator.
      var separator = '\n';
      expect(
        await file.readAsString(),
        'Hello world${separator}Hello world$separator',
      );
      if (Platform.isWindows) {
        stdout.writeln('report: echo output \\n');
      }
    } catch (_) {
      if (Platform.isWindows) {
        // Old test
        var separator = Platform.isWindows ? '\r\n' : '\n';
        expect(
          await file.readAsString(),
          'Hello world${separator}Hello world$separator',
        );
        if (Platform.isWindows) {
          stdout.writeln('report: echo output \\r\\n');
        }
      } else {
        rethrow;
      }
    }
  });

  test('user', () {
    if (Platform.isWindows) {
      expect(userHomePath, Platform.environment['USERPROFILE']);
      expect(userAppDataPath, Platform.environment['APPDATA']);
    } else {
      expect(userHomePath, Platform.environment['HOME']);
      expect(userAppDataPath, join(Platform.environment['HOME']!, '.config'));
    }
  });

  test('userLoadEnvFile', () async {
    //print(a);
    var path = join('test', 'data', 'test_env1.yaml');
    userLoadEnvFile(path);
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
    path = join('test', 'data', 'test_env_dummy_file.yaml');
    userLoadEnvFile(path);
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
  });

  test('userLoadEnv', () async {
    userLoadEnv(vars: {'test': '1'}, paths: ['my_path']);
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
    userLoadEnv();
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
  });

  test('ShellException bad command', () async {
    var shell = Shell();
    try {
      await shell.run('dummy_command_that_does_not_exist');
    } on ShellException catch (e) {
      expect(e.shellCommand.toString(), 'dummy_command_that_does_not_exist');
      expect(e.command.toString(), 'dummy_command_that_does_not_exist');
      expect(e.message.contains('workingDirectory'), isTrue);
    }
  });
  test('ShellException bad directory', () async {
    var shell = Shell(workingDirectory: 'dummy_directory_that_does_not_exist');
    try {
      await shell.run('dart --version');
    } on ShellException catch (e) {
      expect(
        e.command!.workingDirectory,
        'dummy_directory_that_does_not_exist',
      );
      expect(e.message.contains('workingDirectory'), isTrue);
    }
  });
  test('User path', () async {
    // TODO test on other platform
    if (Platform.isLinux) {
      var environment = {
        'PATH': '${absolute('test/src')}:${platformEnvironment['PATH']}',
      };
      print(environment);
      var shell = Shell(
        environment: environment,
        includeParentEnvironment: false,
      );
      await shell.run(currentDirScriptName);
    }
  });
  test(
    'flutter_resolve',
    () async {
      // Edge case finding flutter from dart
      if (Platform.isLinux) {
        var paths = platformEnvironment['PATH']!.split(':')
          ..removeWhere((element) => element.endsWith('flutter/bin'));

        paths.insert(0, dartSdkBinDirPath);
        print(paths);
        var environment = {'PATH': paths.join(':')};
        print(environment);
        var shell = Shell(
          environment: environment,
          includeParentEnvironment: false,
        );
        await shell.run('flutter --version');
      }
    },
    // skip: !isFlutterSupportedSync ||
    skip: true,
  );
  // This is plain wrong now...assumed dart below flutter which will no longer be the case

  test('flutter info', () async {
    expect(await getFlutterBinVersion(), isNotNull);
    expect(await getFlutterBinChannel(), isNotNull);
  }, skip: !isFlutterSupportedSync);

  test('dart version', () async {
    // Try to get the version in 2 different ways
    var sh = Shell();

    var whichDart = await which('dart');
    var resolvedVersion = parseDartBinVersionOutput(
      (await sh.runExecutableArguments(dartExecutable!, [
        '--version',
      ])).stderr.toString(),
    );
    var resolvedVersionSync = parseDartBinVersionOutput(
      (sh.runExecutableArgumentsSync(dartExecutable!, [
        '--version',
      ])).stderr.toString(),
    );
    var whichVersion = parseDartBinVersionOutput(
      (await sh.runExecutableArguments(whichDart!, [
        '--version',
      ])).stderr.toString(),
    );
    var version = parseDartBinVersionOutput(
      (await sh.runExecutableArguments('dart', [
        '--version',
      ])).stderr.toString(),
    );
    expect(version, resolvedVersion);
    expect(version, whichVersion);
    expect(version, resolvedVersionSync);
  });

  test('verbose non ascii char', () async {
    await ensureEchoExe();
    var controller = ShellLinesController();
    var shell = Shell(
      stdout: controller.sink,
      verbose: true,
      environment: ShellEnvironment()..aliases['echo'] = '$echoExe -o',
    );
    await shell.run('echo 你好é');
    controller.close();
    if (!Platform.isWindows) {
      expect(await controller.stream.toList(), [
        '\$ ${shellArgument(echoExeAbsolutePath)} -o 你好é',
        '你好é',
      ]);
    }
  });

  test('var set/get/delete', () async {
    var localFile = '.dart_tool/process_run/test/local1.yaml';
    var userFile = '.dart_tool/process_run/test/user1.yaml';
    var dsCommand = 'dart run bin/shell.dart';
    var safeShellEnvironment = ShellEnvironment()
      ..aliases['ds'] = dsCommand
      ..vars[userEnvFilePathEnvKey] = userFile
      ..vars[localEnvFilePathEnvKey] = localFile;

    var shell = Shell(environment: safeShellEnvironment, verbose: true);
    expect(shell.options.environment.aliases['ds'], dsCommand);
    var keyName = 'TEST_VALUE';
    var userKeyName = 'USER_TEST_VALUE';

    try {
      await File(localFile).delete();
    } catch (_) {}
    try {
      await File(userFile).delete();
    } catch (_) {}
    expect(File(localFile).existsSync(), isFalse);
    shell = await shell.shellVarOverride(keyName, 'dummy1');
    expect(shell.options.environment.aliases['ds'], dsCommand);
    expect(shell.options.environment.vars[keyName], 'dummy1');
    expect(File(localFile).existsSync(), isTrue);
    expect(File(userFile).existsSync(), isFalse);
    shell = await shell.shellVarOverride(userKeyName, 'dummy2', local: false);
    expect(File(userFile).existsSync(), isTrue);
    expect(shell.options.environment.vars[keyName], 'dummy1');
    expect(shell.options.environment.vars[userKeyName], 'dummy2');

    //await safeShell.run('ds env var set TEST_VALUE dummy1');
    var text = (await shell.run('ds env var get $keyName')).outText;
    expect(text, contains('dummy1'));
    //await Shell().run('ds env var delete TEST_VALUE');
    shell = await shell.shellVarOverride(keyName, null);
    expect(shell.options.environment.vars.containsKey(keyName), isFalse);
    text = (await shell.run('ds env var get $keyName')).outText;
    expect(text, isNot(contains('dummy1')));
    expect(shell.options.environment.aliases['ds'], dsCommand);
  });

  test('cloneWithOptions', () async {
    var shell = Shell().cloneWithOptions(ShellOptions(workingDirectory: 'a/b'));
    expect(shell.path, 'a/b');
    expect(shell.options.workingDirectory, 'a/b');
  });
}
