@TestOn("vm")

import 'package:process_run/src/common/import.dart';
import 'process_run_test_common.dart';
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

    test('stdin', () async {
      ProcessCmd cmd = dartCmd([echoScriptPath, '--stdin', 'in']);
      ProcessResult result = await runCmd(cmd);
      expect(result.stderr, '');
      expect(result.stdout, "in\n");
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);
    }, onPlatform: {"windows": new Skip("failing")});

    test('connect_stdin', () async {
      ProcessCmd cmd = dartCmd([echoScriptPath, '--stdin']);
      StreamController<List<int>> streamController = new StreamController();

      Future<ProcessResult> future =
          runCmd(cmd, stdin: streamController.stream);

      streamController.add("in".codeUnits);
      streamController.close();
      ProcessResult result = await future;
      expect(result.stderr, '');
      expect(result.stdout, "in");
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);

      /*

      TestSink<List<int>> out = new TestSink();
      result = await runCmd(cmd, verbose: true, stdout: out);
      expect(out.results.length, 2);
      expect(SYSTEM_ENCODING.decode(out.results[0].asValue.value),
          "\$ dart ${echoScriptPath} --stdout out\n");
      expect(SYSTEM_ENCODING.decode(out.results[1].asValue.value), "out");
      */
    });

    test('connect_stdout', () async {
      ProcessCmd cmd = dartCmd([echoScriptPath, '--stdout', 'out']);
      ProcessResult result = await runCmd(cmd);
      expect(result.stderr, '');
      expect(result.stdout, "out");
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);

      TestSink<List<int>> out = new TestSink();
      result = await runCmd(cmd, verbose: true, stdout: out);
      expect(out.results.length, 2);
      expect(SYSTEM_ENCODING.decode(out.results[0].asValue.value),
          "\$ dart ${echoScriptPath} --stdout out\n");
      expect(SYSTEM_ENCODING.decode(out.results[1].asValue.value), "out");
    });

    test('connect_stderr', () async {
      ProcessCmd cmd = dartCmd([echoScriptPath, '--stderr', 'err']);
      ProcessResult result = await runCmd(cmd);
      expect(result.stderr, 'err');
      expect(result.stdout, '');
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);

      TestSink<List<int>> err = new TestSink();
      result = await runCmd(cmd, stderr: err);
      expect(err.results.length, 1);
      expect(SYSTEM_ENCODING.decode(err.results[0].asValue.value), "err");
    });
  });
}
