@TestOn("vm")
library process_run.dartbin_test;

import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/src/script_filename.dart';
import 'package:process_run/which.dart';

void main() => defineTests();

void defineTests() {
  group('dartbin', () {
    group('dart', () {
      test('run_dart', () async {
        ProcessResult result = await Process.run('dart', ['--version']);
        expect(result.stderr.toLowerCase(), contains("dart"));
        expect(result.stderr.toLowerCase(), contains("version"));
        // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
      });

      test('run', () async {
        ProcessResult result = await Process.run(dartExecutable, ['--version']);
        expect(result.stderr.toLowerCase(), contains("dart"));
        expect(result.stderr.toLowerCase(), contains("version"));
        // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
      });

      test('dartExecutable_path', () {
        expect(isAbsolute(dartExecutable), isTrue);
        expect(
            Directory(join(dirname(dartExecutable), 'snapshots')).existsSync(),
            isTrue);
      });

      test('dart_empty_param', () async {
        ProcessResult result = await Process.run(dartExecutable, []);
        expect(result.exitCode, 255);
      });

      test('dart_null_param', () async {
        try {
          await Process.run(dartExecutable, null);
          fail("should fail");
        } on ArgumentError catch (_) {}
      });
    });

    test('which', () {
      var whichDart = whichSync('dart');
      // might not be in path during the test
      if (whichDart != null) {
        expect(basename(whichDart), getBashOrExeExecutableFilename('dart'));
      }
    });

    group('help', () {
      test('dart', () async {
        ProcessResult result = await Process.run(dartExecutable, ['--help']);
        expect(result.exitCode, 0);
        // help is on stderr
        expect(result.stdout, "");
        expect(result.stderr, contains("Usage: dart "));

        // Version is on stderr
        result = await Process.run(dartExecutable, ['--version']);
        expect(result.stdout, "");
        expect(result.stderr, contains("Dart VM"));
      });
    });
  });
}
