@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process_run/process_run.dart';
import 'package:process_run_test/echo/compile_echo.dart';
import 'package:test/test.dart';

void main() async {
  var echoExecutable = await compileEcho();
  echoTests(EchoTestContext(echoExecutable));
}

class _EchoTestContext implements EchoTestContext {
  @override
  final String echo;

  _EchoTestContext(this.echo);
}

class _LazyEchoTestContext implements EchoTestContext {
  final String Function() _echoProvider;
  String? _echo;

  _LazyEchoTestContext(this._echoProvider);

  @override
  String get echo => _echo ??= _echoProvider();
}

abstract class EchoTestContext {
  factory EchoTestContext(String echo) => _EchoTestContext(echo);
  factory EchoTestContext.lazy(String Function() echoProvider) =>
      _LazyEchoTestContext(echoProvider);
  String get echo;
}

void echoTests(EchoTestContext testContext) {
  late String echo;
  setUpAll(() {
    echo = testContext.echo;
  });
  group('echo', () {
    test('run echo', () async {
      await run('$echo --stdout test');
    });
    Future runCheck(
      Object? Function(ProcessResult result) check,
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
      var result = await runExecutableArguments(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding,
        stdout: stdout,
      );

      check(result);
    }

    test('stdout', () async {
      void checkOut(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, 'out');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      void checkOutWriteLine(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, 'out\n');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      void checkEmpty(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await runCheck(checkOut, echo, ['--stdout', 'out']);
      await runCheck(checkEmpty, echo, []);
      await runCheck(checkOutWriteLine, echo, [
        '--stdout',
        'out',
        '--write-line',
      ]);
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
        expect(result.stdout, <int>[]);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await runCheck(check123, echo, [
        '--stdout-hex',
        '010203',
      ], stdoutEncoding: null);
      await runCheck(checkEmpty, echo, [], stdoutEncoding: null);
    });

    group('stdout_env', () {
      test('var', () async {
        var result = await runExecutableArguments(echo, [
          '--stdout-env',
          'PATH',
        ]);
        //devPrint(result.stdout.toString());
        expect(result.stdout.toString().trim(), isNotEmpty);

        result = await runExecutableArguments(echo, [
          '--stdout-env',
          '__dummy_that_will_never_exists__',
        ]);
        //devPrint(result.stdout.toString());
        expect(result.stdout.toString().trim(), isEmpty);

        result = await runExecutableArguments(
          echo,
          ['--stdout-env', '__CUSTOM'],
          environment: <String, String>{'__CUSTOM': '12345'},
        );
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

      void checkErrWriteLine(ProcessResult result) {
        expect(result.stderr, 'err\n');
        expect(result.stdout, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      void checkEmpty(ProcessResult result) {
        expect(result.stderr, '');
        expect(result.stdout, '');
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await runCheck(checkErr, echo, ['--stderr', 'err']);
      await runCheck(checkErrWriteLine, echo, [
        '--stderr',
        'err',
        '--write-line',
      ]);
      await runCheck(checkEmpty, echo, []);
    });

    test('stdin', () async {
      final inCtrl = StreamController<List<int>>();
      final processResultFuture = runExecutableArguments(echo, [
        '--stdin',
      ], stdin: inCtrl.stream);
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
        expect(result.stderr, <int>[]);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 0);
      }

      await runCheck(check123, echo, [
        '--stderr-hex',
        '010203',
      ], stderrEncoding: null);
      await runCheck(checkEmpty, echo, [], stderrEncoding: null);
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

      await runCheck(check123, echo, ['--exit-code', '123']);
      await runCheck(check0, echo, []);
    });

    test('crash', () async {
      void check(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, isNotEmpty);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 255);
      }

      await runCheck(check, echo, ['--exit-code', 'crash']);
    });
  });
}
