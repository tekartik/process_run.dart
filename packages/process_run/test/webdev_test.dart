@TestOn('vm')
library process_run.dartfmt_test;

import 'dart:convert';

import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

void main() => defineTests();

void defineTests() {
  group('webdev', () {
    setUp(() async {
      var lines = LineSplitter.split(
          (await runCmd(PubCmd(['global', 'list']))).stdout as String);
      for (var line in lines) {
        if (line.split(' ')[0] == 'webdev') {
          return;
        }
      }
      await runCmd(PubCmd(['global', 'activate', 'webdev']));
    });
    test('help', () async {
      final result = await runCmd(WebDevCmd(['--help']));
      expect(result.exitCode, 0);
      expect(result.stdout, contains('Usage: webdev'));

      /*
      this does not work when ran from IDE
      // The raw version is displayed
      result = await runCmd(WebDevCmd(['--version'])..runInShell = true);
      var version = Version.parse((result.stdout as String).trim());
      expect(version, greaterThan(Version(1, 0, 0)));
      expect(result.exitCode, 0);
      */
    });
  },
      // Setup (webdev) could be long
      timeout: const Timeout(Duration(seconds: 300)));
}
