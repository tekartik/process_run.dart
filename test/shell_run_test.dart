@TestOn("vm")
library process_run.test.shell_run_test;

import 'package:process_run/shell.dart';
import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

@deprecated
bool devTrue = true;
// bool debug = devTrue;
bool debug = false;

void main() {
  group('Shell', () {
    test('userEnvironment', () async {
      await run(
          'dart example/echo.dart ${shellArgument(userEnvironment.toString())}',
          verbose: false);

      expect(userEnvironment.length, greaterThan(shellEnvironment.length));
    });
    test('shellEnvironment', () async {
      await run(
          'dart example/echo.dart ${shellArgument(shellEnvironment.toString())}',
          verbose: false);
    });
  });
}
