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
      ProcessCmd cmd = dartCmd(['--version']);
      expect(cmd.executable, dartExecutable);
      expect(cmd.arguments, ['--version']);
      ProcessResult result = await runCmd(cmd);
      expect(result.stderr.toLowerCase(), contains("dart"));
      expect(result.stderr.toLowerCase(), contains("version"));
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
    });
    test('others', () async {
      expect((await runCmd(dartCmd(['--help']))).exitCode, 0);
      expect((await runCmd(dartfmtCmd(['--help']))).exitCode, 0);
      expect((await runCmd(dartanalyzerCmd(['--help']))).exitCode, 0);
      expect((await runCmd(dart2jsCmd(['--help']))).exitCode, 0);
      expect((await runCmd(dartdocCmd(['--help']))).exitCode, 0);
      expect((await runCmd(dartdevcCmd(['--help']))).exitCode, 0);
      expect((await runCmd(pubCmd(['--help']))).exitCode, 0);
    });

    test('toString', () {
      expect(pubCmd(['--help']).toString(), 'pub --help');
      expect(dartdocCmd(['--help']).toString(), 'dartdoc --help');
      expect(dart2jsCmd(['--help']).toString(), 'dart2js --help');
      expect(dartdevcCmd(['--help']).toString(), 'dartdevc --help');
      expect(dartanalyzerCmd(['--help']).toString(), 'dartanalyzer --help');
      expect(dartfmtCmd(['--help']).toString(), 'dartfmt --help');
      expect(dartCmd(['--help']).toString(), 'dart --help');
    });
  });
}
