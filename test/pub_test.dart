@TestOn("vm")
library process_run.pub_test;

import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/shell.dart';
import 'package:process_run/which.dart';
import 'package:pub_semver/pub_semver.dart';

void main() => defineTests();

void defineTests() {
  group('pub', () {
    test('help', () async {
      ProcessResult result = await runCmd(PubCmd(['--help']));
      expect(result.exitCode, 0);
      // Every other commands write to stdout but dartanalyzer
      expect(result.stdout, contains("Usage: pub"));

      // pub version
      result =
          await runCmd(PubCmd(['--version'])..includeParentEnvironment = false);
      var version =
          Version.parse((result.stdout as String).trim().split(" ").last);
      // 2.0.0+ now!
      expect(version, greaterThan(Version(1, 24, 3)));
      expect(result.exitCode, 0);
    }, skip: Platform.isWindows);

    test('which', () {
      var whichPub = whichSync('pub');
      // might not be in path during the test
      if (whichPub != null) {
        expect(basename(whichPub), getBashOrBatExecutableFilename('pub'));
      }
    });
  });
}
