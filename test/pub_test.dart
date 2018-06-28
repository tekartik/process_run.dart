@TestOn("vm")

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/dartbin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'dart:io';

void main() => defineTests();

void defineTests() {
  group('pub', () {
    test('help', () async {
      ProcessResult result = await devRunCmd(pubCmd(['--help']));
      expect(result.exitCode, 0);
      // Every other commands write to stdout but dartanalyzer
      expect(result.stdout, contains("Usage: pub"));

      // dartanalyzer version 2.0.0-dev.63.0
      result = await runCmd(pubCmd(['--version']));
      var version =
          new Version.parse((result.stdout as String).trim().split(" ").last);
      expect(version, greaterThan(new Version(1, 0, 0)));
      expect(result.exitCode, 0);
    });
  });
}
