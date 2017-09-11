@TestOn("vm")
import 'dart:convert';
import 'package:process_run/cmd_record.dart';
import 'package:process_run/src/common/import.dart';
import 'process_run_test_common.dart';
import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart';
import 'dart:io';

void main() {
  group('cmd_record', () {
    test('version', () async {
      ProcessResult result =
          await runCmd(dartCmd([cmdRecordScriptPath, '--version']));
      expect(result.stderr.toLowerCase(), contains("version"));
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
    });

    test('out', () async {
      History history = new History();
      ProcessCmd cmd = dartCmd([echoScriptPath, '--stdout', 'out']);
      await record(cmd.executable, cmd.arguments, history: history);
      //devPrint(JSON.encode(history));
      expect(history.outItems.first.line, "out");
    }, skip: true);

    test('err', () async {
      History history = new History();
      ProcessCmd cmd = dartCmd([echoScriptPath, '--stderr', 'err']);
      await record(cmd.executable, cmd.arguments, history: history);
      //devPrint(JSON.encode(history));
      expect(history.errItems.first.line, "err");
    }, onPlatform: {"windows": new Skip("failing")});

    test('in', () async {
      History history = new History();
      ProcessCmd cmd = dartCmd([echoScriptPath, '--stdin']);
      StreamController inController = new StreamController();
      Future future = record(cmd.executable, cmd.arguments,
          inStream: inController.stream, history: history);
      inController.add(UTF8.encode("in"));
      inController.close();
      await future;
      //devPrint(JSON.encode(history));
      expect(history.inItems.first.line, "in");
    }, skip: true);
  });
}
