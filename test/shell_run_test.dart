@TestOn("vm")
library process_run.test.shell_run_test;

import 'package:process_run/shell.dart';
import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

/// Truncate at max element.
String stringTruncate(String text, int len) {
  if (text == null || text.length <= len) {
    return text;
  }
  return text.substring(0, len);
}

void main() {
  group('Shell', () {
    test('userEnvironment', () async {
      await run(
          'dart example/echo.dart ${shellArgument(stringTruncate(userEnvironment.toString(), 1500))}',
          verbose: false);

      expect(userEnvironment.length,
          greaterThanOrEqualTo(shellEnvironment.length));
      expect(userEnvironment.length,
          greaterThanOrEqualTo(platformEnvironment.length));
    });
    test('shellEnvironment', () async {
      await run(
          'dart example/echo.dart ${shellArgument(stringTruncate(shellEnvironment.toString(), 1500))}',
          verbose: false);
    });
  });
}
