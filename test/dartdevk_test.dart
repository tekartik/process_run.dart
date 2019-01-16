@TestOn("vm")
library process_run.dartdevc_test;

import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart';

void main() {
  group('dartdevk', () {
    test('help', () async {
      ProcessResult result = await runCmd(DartDevkCmd(['--help']));
      //expect(result.stdout, contains("Usage: dartdevk"));
      expect(result.exitCode, 0);
    });
    // version not supported yet
    test('version', () async {
      ProcessResult result = await runCmd(DartDevkCmd(['--version']));
      //expect(result.stdout, contains("dartdevk"));
      expect(result.exitCode, 0);
    }, skip: true);
  }, skip: true);
}
