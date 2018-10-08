@TestOn("vm")
library process_run.process_run_test;

import 'dart:io';
import 'package:dev_test/test.dart';
import 'package:process_run/dartbin.dart';
import 'package:path/path.dart';
import 'package:process_run/process_run.dart';
import 'process_run_test_common.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  group('toString', () {
    test('argumentsToString', () {
      expect(argumentToString(''), '""');
      expect(argumentToString('a'), 'a');
      expect(argumentToString(' '), '" "');
      expect(argumentToString('\t'), '"\t"');
      expect(argumentToString('\n'), '"\n"');
      expect(argumentToString('\''), '"\'"');
      expect(argumentToString('"'), '\'"\'');
    });
    test('argumentsToString', () {
      expect(argumentsToString([]), '');
      expect(argumentsToString(["a"]), 'a');
      expect(argumentsToString(["a", "b"]), 'a b');
      expect(argumentsToString([' ']), '" "');
      expect(argumentsToString(['" ']), '\'" \'');
      expect(argumentsToString(['""\'']), '"\\"\\"\'"');
      expect(argumentsToString(['\t']), '"\t"');
      expect(argumentsToString(['\n']), '"\n"');
      expect(argumentsToString(['a', 'b\nc', 'd']), 'a "b\nc" d');
    });

    test('executableArgumentsToString', () {
      expect(executableArgumentsToString('cmd', null), 'cmd');
      expect(executableArgumentsToString('cmd', []), 'cmd');
      expect(executableArgumentsToString('cmd', ['a']), 'cmd a');
      expect(executableArgumentsToString('cmd', ["a", "b"]), 'cmd a b');
      expect(executableArgumentsToString('cmd', [' ']), 'cmd " "');
      expect(executableArgumentsToString('cmd', [' ']), 'cmd " "');
      expect(executableArgumentsToString('cmd', ['"']), 'cmd \'"\'');
    });
  });

  group('run', () {
    Future _runCheck(
      check(ProcessResult result),
      String executable,
      List<String> arguments, {
      String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding,
      StreamSink<List<int>> stdout,
    }) async {
      ProcessResult result = await Process.run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding,
      );
      check(result);
      result = await run(executable, arguments,
          workingDirectory: workingDirectory,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment,
          runInShell: runInShell,
          stdoutEncoding: stdoutEncoding,
          stderrEncoding: stderrEncoding,
          stdout: stdout);
      check(result);
    }

    test('stdout', () async {
      checkOut(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, "out");
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      checkEmpty(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await _runCheck(
          checkOut, dartExecutable, [echoScriptPath, '--stdout', 'out']);
      await _runCheck(checkEmpty, dartExecutable, [echoScriptPath]);
    });

    test('stdout_bin', () async {
      check123(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, [1, 2, 3]);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      checkEmpty(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, []);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await _runCheck(
          check123, dartExecutable, [echoScriptPath, '--stdout-hex', '010203'],
          stdoutEncoding: null);
      await _runCheck(checkEmpty, dartExecutable, [echoScriptPath],
          stdoutEncoding: null);
    });

    test('stderr', () async {
      checkErr(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, "err");
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      checkEmpty(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await _runCheck(
          checkErr, dartExecutable, [echoScriptPath, '--stderr', 'err'],
          stdout: stdout);
      await _runCheck(checkEmpty, dartExecutable, [echoScriptPath]);
    });

    test('stdin', () async {
      StreamController<List<int>> inCtrl = StreamController();
      Future<ProcessResult> processResultFuture = run(
          dartExecutable, [echoScriptPath, '--stdin'],
          stdin: inCtrl.stream);
      inCtrl.add("in".codeUnits);
      inCtrl.close();
      ProcessResult result = await processResultFuture;

      expect(result.stdout, 'in');
      expect(result.stderr, "");
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);
    });

    test('stderr_bin', () async {
      check123(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, [1, 2, 3]);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      checkEmpty(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, []);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await _runCheck(
          check123, dartExecutable, [echoScriptPath, '--stderr-hex', '010203'],
          stderrEncoding: null);
      await _runCheck(checkEmpty, dartExecutable, [echoScriptPath],
          stderrEncoding: null);
    });

    test('exitCode', () async {
      check123(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 123);
      }

      check0(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await _runCheck(
          check123, dartExecutable, [echoScriptPath, '--exit-code', '123']);
      await _runCheck(check0, dartExecutable, [echoScriptPath]);
    });

    test('crash', () async {
      check(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, isNotEmpty);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 255);
      }

      await _runCheck(
          check, dartExecutable, [echoScriptPath, '--exit-code', 'crash']);
    });

    test('no_argument', () async {
      try {
        await Process.run(dartExecutable, null);
      } on ArgumentError catch (_) {
        // Invalid argument(s): Arguments is not a List: null
      }
      try {
        await run(dartExecutable, null);
      } on ArgumentError catch (_) {
        // Invalid argument(s): Arguments is not a List: null
      }
    });

    test('invalid_executable', () async {
      try {
        await Process.run(dummyExecutable, []);
      } on ProcessException catch (_) {
        // ProcessException: No such file or directory
      }

      try {
        await run(dummyExecutable, []);
      } on ProcessException catch (_) {
        // ProcessException: No such file or directory
      }
    });

    test('system_command', () async {
      // read pubspec.yaml
      List<String> lines = const LineSplitter()
          .convert(await File(join(projectTop, 'pubspec.yaml')).readAsString());

      check(ProcessResult result) {
        expect(const LineSplitter().convert(result.stdout.toString()), lines);
        expect(result.stderr, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      // use 'cat' on mac and linux
      // use 'type' on windows

      if (Platform.isWindows) {
        await _runCheck(check, 'type', ['pubspec.yaml'],
            workingDirectory: projectTop, runInShell: true);
      } else {
        await _runCheck(check, 'cat', ['pubspec.yaml'],
            workingDirectory: projectTop);
      }
    });

    test('windows_system_command', () async {
      if (Platform.isWindows) {
        if (Platform.isWindows) {
          ProcessResult result;

          result = await run('cmd', ['/c', 'echo', "hi"]);
          expect(result.stdout, 'hi\r\n');
          expect(result.stderr, '');
          expect(result.pid, isNotNull);
          expect(result.exitCode, 0);

          await run('echo', ["hi"], runInShell: true);
          expect(result.stdout, 'hi\r\n');
          expect(result.stderr, '');
          expect(result.pid, isNotNull);
          expect(result.exitCode, 0);

          // not using runInShell crashes
          try {
            await run('echo', ["hi"]);
          } on ProcessException catch (_) {
            // ProcessException: not fount
          }
        }
      }
    });
  });
}
