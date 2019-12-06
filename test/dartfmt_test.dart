@TestOn('vm')
library process_run.dartfmt_test;

import 'package:process_run/cmd_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() => defineTests();

void defineTests() {
  group('dartfmt', () {
    test('help', () async {
      var result = await runCmd(DartFmtCmd(['--help']));
      expect(result.exitCode, 0);
      expect(result.stdout, contains('Usage:'));
      expect(result.stdout, contains('dartfmt'));

      // The raw version is displayed
      result = await runCmd(DartFmtCmd(['--version']));
      var version = Version.parse((result.stdout as String).trim());
      expect(version, greaterThan(Version(1, 0, 0)));
      expect(result.exitCode, 0);
    });
  });
}
