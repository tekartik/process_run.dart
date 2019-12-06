@TestOn('vm')
library process_run.process_run_out_test;

import 'dart:io';
import 'package:test/test.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/process_run.dart';
import 'process_run_test_common.dart';

void main() {
  test('connect_stdout', () async {
    await stdout.flush();
    final result = await run(
        dartExecutable, [echoScriptPath, '--stdout', 'out'],
        stdout: stdout);
    expect(result.stderr, '');
    expect(result.stdout, 'out');
    expect(result.pid, isNotNull);
    expect(result.exitCode, 0);
    await stdout.flush();
  });

  test('connect_stderr', () async {
    await stderr.flush();
    final result = await run(
        dartExecutable, [echoScriptPath, '--stderr', 'err'],
        stderr: stderr);
    expect(result.stdout, '');
    expect(result.stderr, 'err');
    expect(result.pid, isNotNull);
    expect(result.exitCode, 0);
    await stderr.flush();
  });
}
