@TestOn("vm")

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/dartbin_cmd.dart';
import 'package:process_run/src/process_cmd.dart';
import 'package:process_run/dartbin.dart';
import 'dart:io';
import 'package:path/path.dart';

void main() {
  group('dartbin_cmd', () {
    test('arguments', () {
      _expect(ProcessCmd cmd, String snapshotCmd) {
        expect(cmd.executable, dartExecutable);
        expect(cmd.arguments, [
          join(dirname(dartExecutable), 'snapshots',
              '${snapshotCmd}.dart.snapshot'),
          '--help'
        ]);
      }

      _expect(dartfmtCmd(['--help']), 'dartfmt');
      _expect(dartanalyzerCmd(['--help']), 'dartanalyzer');
      expect(dart2jsCmd(['--help']).arguments, [
        join(dirname(dartExecutable), 'snapshots', 'dart2js.dart.snapshot'),
        '--library-root=${dartSdkDirPath}',
        '--help'
      ]);
      expect(dartdocCmd(['--help']).arguments, [
        '--packages=${join(dartSdkDirPath, 'bin', 'snapshots', 'resources', 'dartdoc', '.packages')}',
        join(dirname(dartExecutable), 'snapshots', 'dartdoc.dart.snapshot'),
        '--help'
      ]);
      _expect(pubCmd(['--help']), 'pub');
    });

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
      expect((await runCmd(pubCmd(['--help']))).exitCode, 0);
    });

    test('toString', () {
      expect(pubCmd(['--help']).toString(), 'pub --help');
      expect(dartCmd(['--help']).toString(), 'dart --help');
    });
  });
}
