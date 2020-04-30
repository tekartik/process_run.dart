@TestOn('vm')
library process_run.test.shell_run_test;

import 'dart:io';

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
  group('shell_run', () {
    test('public', () {
      // ignore: unnecessary_statements
      getFlutterBinVersion;
      // ignore: unnecessary_statements
      getFlutterBinChannel;
      isFlutterSupported;
      isFlutterSupportedSync;
      dartVersion;
      dartChannel;
    });
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

    test('--version', () async {
      for (var bin in [
        'dartdoc',
        'dart',
        'pub',
        'dartfmt',
        'dart2js',
        'dartanalyzer',
      ]) {
        stdout.writeln('');
        var result = (await run('$bin --version',
                throwOnError: false, verbose: false, commandVerbose: true))
            .first;
        stdout.writeln('stdout: ${result.stdout.toString().trim()}');
        stdout.writeln('stderr: ${result.stderr.toString().trim()}');
        stdout.writeln('exitCode: ${result.exitCode}');
      }
    });
  });
}
