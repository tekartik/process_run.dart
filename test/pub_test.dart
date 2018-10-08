@TestOn("vm")
library process_run.pub_test;

import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart';
import 'package:pub_semver/pub_semver.dart';

void main() => defineTests();

void defineTests() {
  group('pub', () {
    test('help', () async {
      ProcessResult result = await runCmd(pubCmd(['--help']));
      expect(result.exitCode, 0);
      // Every other commands write to stdout but dartanalyzer
      expect(result.stdout, contains("Usage: pub"));

      // dartanalyzer version 2.0.0-dev.63.0
      result = await runCmd(pubCmd(['--version']));
      var version =
          Version.parse((result.stdout as String).trim().split(" ").last);
      // 2.0.0+ now!
      expect(version, greaterThan(Version(1, 24, 3)));
      expect(result.exitCode, 0);
    }, skip: Platform.isWindows);
  });
}
