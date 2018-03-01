@TestOn("vm")

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart' show runCmd;
import 'package:process_run/process_cmd.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'process_run_test_common.dart';
import 'package:process_run/dartbin.dart';

void main() {
  group('process_cmd', () {
    test('simple', () {
      ProcessCmd cmd = new ProcessCmd("a", []);
      expect(cmd.executable, "a");
    });
    test('equals', () {
      ProcessCmd cmd1 = new ProcessCmd("a", []);
      ProcessCmd cmd2 = new ProcessCmd("a", []);
      expect(cmd1, cmd2);
      cmd1.executable = "b";
      expect(cmd1, isNot(cmd2));
      cmd2
        ..executable = "b"
        ..arguments = ['1'];
      expect(cmd1, isNot(cmd2));
    });
    test('clone', () {
      ProcessCmd cmd1 = new ProcessCmd("a", []);
      ProcessCmd cmd2 = cmd1.clone();
      expect(cmd1, cmd2);
      cmd1.executable = "b";
      expect(cmd1, isNot(cmd2));
    });
    test('dart_cmd', () async {
      ProcessResult result =
          await runCmd(processCmd(dartExecutable, ['--version']));
      expect(result.stderr.toLowerCase(), contains("dart"));
      expect(result.stderr.toLowerCase(), contains("version"));
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
    });
    // only duplicate this one
    test('system_command', () async {
      // read pubspec.yaml
      Iterable<String> lines = LineSplitter.split(
          await new File(join(dirname(testDir), 'pubspec.yaml'))
              .readAsString());

      // use 'cat' on mac and linux
      // use 'type' on windows
      ProcessCmd cmd;
      if (Platform.isWindows) {
        cmd = processCmd('type', ['pubspec.yaml'],
            workingDirectory: dirname(testDir), runInShell: true);
      } else {
        cmd = processCmd('cat', ['pubspec.yaml'],
            workingDirectory: dirname(testDir));
      }
      ProcessResult result = await runCmd(cmd);
      expect(LineSplitter.split(result.stdout.toString()), lines);
      expect(result.stderr, '');
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);
    });

    test('processResultToDebugString', () {
      expect(
          LineSplitter.split(processResultToDebugString(
              new ProcessResult(1, 0, "out", "err"))),
          ['exitCode: 0', 'out: out', 'err: err']);
      expect(
          LineSplitter.split(processResultToDebugString(
              new ProcessResult(2, 1, "testout", "testerr"))),
          ['exitCode: 1', 'out: testout', 'err: testerr']);
    });

    test('processCmdToDebugString', () {
      expect(
          LineSplitter
              .split(processCmdToDebugString(new ProcessCmd("cmd", ['arg']))),
          ['cmd: cmd arg']);

      expect(
          LineSplitter.split(processCmdToDebugString(
              new ProcessCmd("cmd", ['arg'])..workingDirectory = "dir")),
          ['dir: dir', 'cmd: cmd arg']);
    });
  });
}
