@TestOn("vm")
library command.test.process_cmd_test_;

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart';
import 'dart:io';

void main() {
  group('runCmd', () {
    test('dartCmd', () async {
      ProcessResult result = await runCmd(dartCmd(['version']));
      expect(result.stderr.toLowerCase(), contains("dart"));
      expect(result.stderr.toLowerCase(), contains("version"));
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
    });
  });
}
