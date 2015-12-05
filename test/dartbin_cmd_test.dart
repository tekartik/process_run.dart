@TestOn("vm")
library command.test.process_cmd_test_;

import 'package:dev_test/test.dart';
import 'package:process_run/cmd/process_cmd.dart';
import 'package:process_run/cmd/dartbin_cmd.dart';
import 'package:process_run/dartbin.dart';
import 'dart:io';
import 'package:path/path.dart';

void main() {
  group('dartbin_cmd', () {
    test('dartCmd', () async {
      ProcessCmd cmd = dartCmd(['version']);
      expect(cmd.executable, dartExecutable);
      expect(cmd.arguments, ['version']);
      ProcessResult result = await cmd.run();
      expect(result.stderr.toLowerCase(), contains("dart"));
      expect(result.stderr.toLowerCase(), contains("version"));
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
    });
    test('others', () async {
      expect((await dartfmtCmd(['--help']).run()).exitCode, 0);
      expect((await dartanalyzerCmd(['--help']).run()).exitCode, 0);
      expect((await dart2jsCmd(['--help']).run()).exitCode, 0);
      expect((await dartdocCmd(['--help']).run()).exitCode, 0);
      expect((await pubCmd(['--help']).run()).exitCode, 0);
    });
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
      _expect(dart2jsCmd(['--help']), 'dart2js');
      _expect(dartdocCmd(['--help']), 'dartdoc');
      _expect(pubCmd(['--help']), 'pub');
    });
  });
}
