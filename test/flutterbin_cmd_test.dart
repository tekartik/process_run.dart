@TestOn("vm")
library process_run.flutterbin_cmd_test;

import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/process_cmd.dart';

void main() {
  group('flutterbin_cmd', () {
    if (isFlutterSupported) {
      test('version', () async {
        //print(flutterExecutablePath);
        ProcessCmd cmd = FlutterCmd(['--version']);
        // expect(cmd.executable, flutterExecutablePath);
        expect(cmd.arguments, ['--version']);
        ProcessResult result = await runCmd(cmd);
        expect(result.stdout.toLowerCase(), contains("dart"));
        expect(result.stdout.toLowerCase(), contains("revision"));
        expect(result.stdout.toLowerCase(), contains("flutter"));
      });
    }
  });
}
