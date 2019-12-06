@TestOn('vm')
library process_run.pub_test;

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/script_filename.dart';
import 'package:process_run/which.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() => defineTests();

void defineTests() {
  group('pub', () {
    test('help', () async {
      var result = await runCmd(PubCmd(['--help']));
      expect(result.exitCode, 0);
      // Every other commands write to stdout but dartanalyzer
      expect(result.stdout, contains('Usage: pub'));

      // pub version
      result = await runCmd(PubCmd(['--version']));

      var version =
          Version.parse((result.stdout as String).trim().split(' ').last);
      // 2.0.0+ now!
      expect(version, greaterThan(Version(1, 24, 3)));
      expect(result.exitCode, 0);
    });

    test('which', () {
      var whichPub = whichSync('pub');
      // might not be in path during the test
      if (whichPub != null) {
        expect(basename(whichPub), getBashOrBatExecutableFilename('pub'));
      }
    });
  });
}
