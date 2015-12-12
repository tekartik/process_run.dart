@TestOn("vm")
library command.test.dartbin_test;

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/dartbin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'dart:io';

void main() => defineTests();

void defineTests() {
  group('dart', () {
    test('run', () async {
      ProcessResult result = await Process.run(dartExecutable, ['--version']);
      expect(result.stderr.toLowerCase(), contains("dart"));
      expect(result.stderr.toLowerCase(), contains("version"));
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
    });

    test('dartExecutable_path', () {
      expect(isAbsolute(dartExecutable), isTrue);
      expect(
          new Directory(join(dirname(dartExecutable), 'snapshots'))
              .existsSync(),
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

    test('dartfmt', () async {
      ProcessResult result =
          await Process.run(dartExecutable, dartfmtArguments(['--help']));
      expect(result.exitCode, 0);
      expect(result.stdout, contains("Usage: dartfmt"));

      // dartfmt has no version option yet
      // Fixed in 1.14.0-dev.4!
      result =
          await Process.run(dartExecutable, dartfmtArguments(['--version']));
      if (new Version.parse(Platform.version.split(' ').first) <
          new Version(1, 14, 0, pre: "4")) {
        expect(result.exitCode, 64);
      } else {
        expect(result.stdout, contains("dartfmt"));
        expect(result.exitCode, 0);
      }
    });

    test('dartanalyzer', () async {
      ProcessResult result =
          await Process.run(dartExecutable, dartanalyzerArguments(['--help']));
      // Weird this is in err instead of out
      expect(result.stderr, contains("Usage: dartanalyzer"));
      expect(result.exitCode, 0);

      result = await Process.run(
          dartExecutable, dartanalyzerArguments(['--version']));
      expect(result.stdout, contains("dartanalyzer"));
      expect(result.exitCode, 0);
    });

    test('dart2js', () async {
      ProcessResult result =
          await Process.run(dartExecutable, dart2jsArguments(['--help']));
      expect(result.stdout, contains("Usage: dart2js"));
      expect(result.exitCode, 0);

      result =
          await Process.run(dartExecutable, dart2jsArguments(['--version']));
      expect(result.stdout, contains("dart2js"));
      expect(result.exitCode, 0);
    });

    test('dartdoc', () async {
      ProcessResult result =
          await Process.run(dartExecutable, dartdocArguments(['--help']));
      expect(result.stdout, contains("Usage: dartdoc"));
      expect(result.exitCode, 0);

      result =
          await Process.run(dartExecutable, dartdocArguments(['--version']));
      expect(result.stdout, contains("dartdoc"));
      expect(result.exitCode, 0);
    });

    test('pub', () async {
      // change false to true to check that you get output
      ProcessResult result =
          await Process.run(dartExecutable, pubArguments(['--help']));
      expect(result.stdout, contains("Usage: pub"));
      expect(result.exitCode, 0);

      result = await Process.run(dartExecutable, pubArguments(['--version']));
      expect(result.stdout, contains("Pub"));
      expect(result.exitCode, 0);
    });
  });
}
