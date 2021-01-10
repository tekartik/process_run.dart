@TestOn('vm')
library process_run.dartanalyzer_test;

import 'package:process_run/cmd_run.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() => defineTests();

void defineTests() {
  group('dartanalyzer', () {
    test('help', () async {
      var result = await runCmd(DartAnalyzerCmd(['--help']));
      expect(result.exitCode, 0);
      // Every other commands write to stdout but dartanalyzer
      expect(result.stderr, contains('Usage: dartanalyzer'));

      // dartanalyzer version 2.0.0-dev.63.0
      result = await runCmd(DartAnalyzerCmd(['--version']));
      var version =
          Version.parse((result.stdout as String).trim().split(' ').last);
      expect(version, greaterThan(Version(1, 0, 0)));
      expect(result.exitCode, 0);
    });
  });
}
