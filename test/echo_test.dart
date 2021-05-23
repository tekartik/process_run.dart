@TestOn('vm')
library process_run.echo_test;

import 'dart:convert';
import 'dart:io';

import 'package:process_run/process_run.dart';
import 'package:process_run/src/common/import.dart';
import 'package:test/test.dart';

import 'process_run_test_common.dart';

var echo = 'dart run example/echo.dart';

void main() {
  group('echo', () {
    Future _runCheck(
      Function(ProcessResult result) check,
      String executable,
      List<String> arguments, {
      String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding? stdoutEncoding = systemEncoding,
      Encoding? stderrEncoding = systemEncoding,
      StreamSink<List<int>>? stdout,
    }) async {
      var result = await Process.run(
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
      result = await runExecutableArguments(executable, arguments,
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
      void checkOut(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, 'out');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      void checkEmpty(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await _runCheck(
          checkOut, dartExecutable!, [echoScriptPath, '--stdout', 'out']);
      await _runCheck(checkEmpty, dartExecutable!, [echoScriptPath]);
    });

    test('stdout_bin', () async {
      void check123(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, [1, 2, 3]);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      void checkEmpty(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, []);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await _runCheck(
          check123, dartExecutable!, [echoScriptPath, '--stdout-hex', '010203'],
          stdoutEncoding: null);
      await _runCheck(checkEmpty, dartExecutable!, [echoScriptPath],
          stdoutEncoding: null);
    });

    group('stdout_env', () {
      test('var', () async {
        var result = await runExecutableArguments(
            dartExecutable!, [echoScriptPath, '--stdout-env', 'PATH']);
        //devPrint(result.stdout.toString());
        expect(result.stdout.toString().trim(), isNotEmpty);

        result = await runExecutableArguments(dartExecutable!, [
          echoScriptPath,
          '--stdout-env',
          '__dummy_that_will_never_exists__'
        ]);
        //devPrint(result.stdout.toString());
        expect(result.stdout.toString().trim(), isEmpty);

        result = await runExecutableArguments(
            dartExecutable!, [echoScriptPath, '--stdout-env', '__CUSTOM'],
            environment: <String, String>{'__CUSTOM': '12345'});
        expect(result.stdout.toString().trim(), '12345');
      });
    });

    test('stderr', () async {
      void checkErr(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, 'err');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      void checkEmpty(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await _runCheck(
          checkErr, dartExecutable!, [echoScriptPath, '--stderr', 'err'],
          stdout: stdout);
      await _runCheck(checkEmpty, dartExecutable!, [echoScriptPath]);
    });

    test('stdin', () async {
      final inCtrl = StreamController<List<int>>();
      final processResultFuture = runExecutableArguments(
          dartExecutable!, [echoScriptPath, '--stdin'],
          stdin: inCtrl.stream);
      inCtrl.add('in'.codeUnits);
      await inCtrl.close();
      final result = await processResultFuture;

      expect(result.stdout, 'in');
      expect(result.stderr, '');
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);
    });

    test('stderr_bin', () async {
      void check123(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, [1, 2, 3]);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      void checkEmpty(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, []);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await _runCheck(
          check123, dartExecutable!, [echoScriptPath, '--stderr-hex', '010203'],
          stderrEncoding: null);
      await _runCheck(checkEmpty, dartExecutable!, [echoScriptPath],
          stderrEncoding: null);
    });

    test('exitCode', () async {
      void check123(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 123);
      }

      void check0(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await _runCheck(
          check123, dartExecutable!, [echoScriptPath, '--exit-code', '123']);
      await _runCheck(check0, dartExecutable!, [echoScriptPath]);
    });

    test('crash', () async {
      void check(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, isNotEmpty);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 255);
      }

      await _runCheck(
          check, dartExecutable!, [echoScriptPath, '--exit-code', 'crash']);
    });
  });
}
