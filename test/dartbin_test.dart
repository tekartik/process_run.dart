@TestOn("vm")
library tekartik_cmdo.test.dartbin_test;

import 'package:dev_test/test.dart';
import 'cmdo_io_test_common.dart';
import 'package:path/path.dart';
import 'package:cmdo/dartbin.dart';
import 'dart:io';

void main() => defineTests();

void defineTests() {
  group('dart', () {
    test('run', () async {
      CommandResult result = await io.run(dartVmBin, ['--version']);
      expect(result.output.errLines.first.toLowerCase(), contains("dart"));
      expect(result.output.errLines.first.toLowerCase(), contains("version"));
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
    });

    test('dartVmBin', () {
      expect(isAbsolute(dartVmBin), isTrue);
      expect(new Directory(join(dirname(dartVmBin), 'snapshots')).existsSync(),
          isTrue);
    });

    test('connectIo', () async {
      // change false to true to check that you get output
      CommandResult result =
          await io.run(dartVmBin, ['--version'], connectIo: false);
      expect(result.output.err, contains("version"));
    });

    test('throw bad dart param', () async {
      CommandResult result = await io.run(dartVmBin, null);
      expect(result.input.executable, equals(dartVmBin));
      expect(result.input.arguments.isEmpty, isTrue);
      expect(result.out.isEmpty, isTrue);
      expect(result.err.isEmpty, isFalse);
      expect(result.exitCode, equals(255));
    });
  });

  group('help', () {
    test('dart', () async {
      CommandResult result = await io.runCmd(dartCmd(['--help']));
      expect(result.exitCode, 0);
      // help is on stderr
      expect(result.err, contains("Usage: dart "));

      // Version is on stderr
      result = await io.runCmd(dartCmd(['--version']));
      expect(result.err, contains("Dart VM"));
    });

    test('dartfmt', () async {
      CommandResult result = await io.runCmd(dartFmtCmd(['--help']));
      expect(result.exitCode, 0);
      expect(result.out, contains("Usage: dartfmt"));

      // dartfmt has no version option yet
      result = await io.runCmd(dartFmtCmd(['--version']));
      expect(result.exitCode, 64);
    });

    test('dartanalyzer', () async {
      CommandResult result =
          await io.runCmd(dartAnalyzerCmd(['--help'])..connectIo = false);
      // Weird this is in err instead of out
      expect(result.err, contains("Usage: dartanalyzer"));
      expect(result.exitCode, 0);

      result =
          await io.runCmd(dartAnalyzerCmd(['--version'])..connectIo = false);
      expect(result.out, contains("dartanalyzer"));
      expect(result.exitCode, 0);
    });

    test('dart2js', () async {
      CommandResult result =
          await io.runCmd(dart2JsCmd(['--help'])..connectIo = false);
      expect(result.out, contains("Usage: dart2js"));
      expect(result.exitCode, 0);

      result = await io.runCmd(dart2JsCmd(['--version'])..connectIo = false);
      expect(result.out, contains("dart2js"));
      expect(result.exitCode, 0);
    });

    test('dartdoc', () async {
      CommandResult result =
          await io.runCmd(dartdocCmd(['--help'])..connectIo = false);
      expect(result.out, contains("Usage: dartdoc"));
      expect(result.exitCode, 0);

      result = await io.runCmd(dartdocCmd(['--version'])..connectIo = false);
      expect(result.out, contains("dartdoc"));
      expect(result.exitCode, 0);
    });

    test('pub', () async {
      // change false to true to check that you get output
      CommandResult result =
          await io.runCmd(pubCmd(['--help'])..connectIo = false);
      expect(result.out, contains("Usage: pub"));
      expect(result.exitCode, 0);

      result = await io.runCmd(pubCmd(['--version'])..connectIo = false);
      expect(result.out, contains("Pub"));
      expect(result.exitCode, 0);
    });
  });
}
