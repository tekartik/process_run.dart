@TestOn("vm")
library process_run.dartbin_cmd_test;

import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/src/dartbin_cmd.dart';
import 'package:process_run/src/process_cmd.dart';

void main() {
  group('dartbin_cmd', () {
    test('dartcmd_arguments', () async {
      ProcessCmd cmd = DartCmd(['--version']);
      expect(cmd.executable, dartExecutable);
      expect(cmd.arguments, ['--version']);
      ProcessResult result = await runCmd(cmd);
      expect(result.stderr.toLowerCase(), contains("dart"));
      expect(result.stderr.toLowerCase(), contains("version"));
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
    });
    test('others', () async {
      expect((await runCmd(DartCmd(['--help']))).exitCode, 0);
      expect((await runCmd(DartFmtCmd(['--help']))).exitCode, 0);
      expect((await runCmd(DartAnalyzerCmd(['--help']))).exitCode, 0);
      expect((await runCmd(Dart2JsCmd(['--help']))).exitCode, 0);
      expect((await runCmd(DartDocCmd(['--help']))).exitCode, 0);
      expect((await runCmd(DartDevcCmd(['--help']))).exitCode, 0);
      expect((await runCmd(PubCmd(['--help']))).exitCode, 0);
      //expect((await runCmd(DartDevkCmd(['--help']))).exitCode, 0);
    });

    test('toString', () {
      expect(PubCmd(['--help']).toString(), 'pub --help');
      expect(DartDocCmd(['--help']).toString(), 'dartdoc --help');
      expect(Dart2JsCmd(['--help']).toString(), 'dart2js --help');
      expect(DartDevcCmd(['--help']).toString(), 'dartdevc --help');
      expect(DartAnalyzerCmd(['--help']).toString(), 'dartanalyzer --help');
      expect(DartFmtCmd(['--help']).toString(), 'dartfmt --help');
      expect(DartCmd(['--help']).toString(), 'dart --help');
    });
  });
}
