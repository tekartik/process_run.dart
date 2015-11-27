@TestOn("vm")
library command.test.process_command_test;

import 'dart:io';
import 'package:dev_test/test.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/process_run.dart';
import 'process_run_test_common.dart';

void main() {
  test('connect_stdout', () async {
    ProcessResult result = await run(
        dartExecutable, [echoScriptPath, '--stdout', 'out'],
        connectStdout: true);
    expect(result.stderr, '');
    expect(result.stdout, "out");
    expect(result.pid, isNotNull);
    expect(result.exitCode, 0);
  });

  test('connect_stderr', () async {
    ProcessResult result = await run(
        dartExecutable, [echoScriptPath, '--stderr', 'err'],
        connectStderr: true);
    expect(result.stdout, '');
    expect(result.stderr, "err");
    expect(result.pid, isNotNull);
    expect(result.exitCode, 0);
  });
}
