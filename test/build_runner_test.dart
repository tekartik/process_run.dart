@TestOn("vm")
library process_run.dartfmt_test;

import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart';

void main() => defineTests();

void defineTests() {
  group('pbr', () {
    test('help', () async {
      ProcessResult result = await runCmd(PbrCmd(['--help']));
      expect(result.exitCode, 0);
      expect(result.stdout, contains("Usage: build_runner"));

      /*
      this does not work when ran from IDE
      // The raw version is displayed
      result = await runCmd(WebDevCmd(['--version'])..runInShell = true);
      var version = Version.parse((result.stdout as String).trim());
      expect(version, greaterThan(Version(1, 0, 0)));
      expect(result.exitCode, 0);
      */
    });
  });
}
