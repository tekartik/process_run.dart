@TestOn("vm")
library process_run.flutterbin_cmd_test;

import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/process_cmd.dart';
import 'package:process_run/src/script_filename.dart';
import 'package:process_run/which.dart';

void main() {
  group('flutterbin_cmd', () {
    test('run_version', () async {
      //print(flutterExecutablePath);
      ProcessCmd cmd = FlutterCmd(['--version']);
      // expect(cmd.executable, flutterExecutablePath);
      expect(cmd.arguments, ['--version']);
      ProcessResult result = await runCmd(cmd);
      expect(result.stdout.toLowerCase(), contains("dart"));
      expect(result.stdout.toLowerCase(), contains("revision"));
      expect(result.stdout.toLowerCase(), contains("flutter"));
    });

    test('get version', () async {
      var version = await getFlutterVersion();
      expect(version, greaterThan(Version(1, 5, 0)));
    });

    test('which', () {
      expect(basename(whichSync('flutter')),
          getBashOrBatExecutableFilename('flutter'));
    });
  }, skip: !isFlutterSupportedSync);
}
