@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process_run/process_run.dart';
import 'package:process_run_test/echo/compile_echo.dart';
import 'package:test/test.dart';

void main() async {
  var echoExecutable = await compileEcho(force: true);
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

/// Echo test context
abstract class EchoTestContext {
  /// Echo test context
  factory EchoTestContext(String echo) => _EchoTestContext(echo);

  /// Lazy init
  factory EchoTestContext.lazy(String Function() echoProvider) =>
      _LazyEchoTestContext(echoProvider);

  /// Echo executable
  String get echo;
}

/// echo tests
void echoTests(EchoTestContext testContext) {
  late String echo; // Safe in run
  late String echoBin;
  late Shell shell;
  setUpAll(() {
    echoBin = testContext.echo;
    echo = shellArgument(echoBin);
    shell = Shell(options: ShellOptions(throwOnError: false));
  });
  group('echo', () {
    test('run echo', () async {
      await shell.run('$echo --stdout test');
    });
    Future runCheck(
      Object? Function(ProcessResult result) check,
      String executable,
      List<String> arguments, {
      Encoding? stdoutEncoding = systemEncoding,
      Encoding? stderrEncoding = systemEncoding,
    }) async {
      var customShell = shell.cloneWithOptions(
        ShellOptions(
          stderrEncoding: stderrEncoding,
          stdoutEncoding: stdoutEncoding,
          throwOnError: false,
        ),
      );
      var result = await customShell.runExecutableArguments(
        executable,
        arguments,
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

      await runCheck(checkOut, echoBin, ['--stdout', 'out']);
      await runCheck(checkEmpty, echoBin, []);
      await runCheck(checkOutWriteLine, echoBin, [
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
      await runCheck(checkEmpty, echoBin, [], stdoutEncoding: null);
    });

    group('stdout_env', () {
      test('var', () async {
        var result = await shell.runExecutableArguments(echoBin, [
          '--stdout-env',
          'PATH',
        ]);
        //devPrint(result.stdout.toString());
        expect(result.stdout.toString().trim(), isNotEmpty);

        result = await shell.runExecutableArguments(echoBin, [
          '--stdout-env',
          '__dummy_that_will_never_exists__',
        ]);
        //devPrint(result.stdout.toString());
        expect(result.stdout.toString().trim(), isEmpty);

        var customShell = shell.cloneWithOptions(
          ShellOptions(environment: <String, String>{'__CUSTOM': '12345'}),
        );
        result = await customShell.runExecutableArguments(echoBin, [
          '--stdout-env',
          '__CUSTOM',
        ]);
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

      await runCheck(checkErr, echoBin, ['--stderr', 'err']);
      await runCheck(checkErrWriteLine, echoBin, [
        '--stderr',
        'err',
        '--write-line',
      ]);
      await runCheck(checkEmpty, echoBin, []);
    });

    test('stdin', () async {
      final inCtrl = StreamController<List<int>>();
      var customShell = shell.cloneWithOptions(
        ShellOptions(stdin: inCtrl.stream),
      );
      final processResultFuture = customShell.runExecutableArguments(echoBin, [
        '--stdin',
      ]);
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

      await runCheck(check123, echoBin, [
        '--stderr-hex',
        '010203',
      ], stderrEncoding: null);
      await runCheck(checkEmpty, echoBin, [], stderrEncoding: null);
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

      await runCheck(check123, echoBin, ['--exit-code', '123']);
      await runCheck(check0, echo, []);
    });

    test('crash', () async {
      void check(ProcessResult result) {
        expect(result.stdout, '');
        expect(result.stderr, isNotEmpty);
        expect(result.pid, isNotNull);
        expect(result.exitCode, 255);
      }

      await runCheck(check, echoBin, ['--exit-code', 'crash']);
    });
  });
}
