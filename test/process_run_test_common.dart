@TestOn("vm")
library command.test.process_command_test;

import 'package:dev_test/test.dart';
import 'command_test_.dart' as _test;
import 'package:command/command_dartbin.dart';
import 'dart:mirrors';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';
import 'package:command/process_command.dart';
import 'package:command/dartbin.dart';
import 'package:command/process_run.dart';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;
String get testDir => dirname(testScriptPath);

String get echoScriptPath => join(dirname(testDir), 'bin', 'echo.dart');

// does not exists
String get dummyExecutable => join(dirname(testDir), 'bin', 'dummy');

void main() {
  test('connect_stdin', () {
    print('Please enter "hi"');
  });

  group('connectStderr', () {});
  group('dart', () {
    test('run', () async {
      ProcessResult result = await run(dartExecutable, ['--version']);
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
      ProcessResult result = await run(dartExecutable, []);
      expect(result.exitCode, 255);
    });

    test('dart_null_param', () async {
      try {
        ProcessResult result = await run(dartExecutable, null);
        fail("should fail");
      } on ArgumentError catch (_) {}
    });
  });
  test('run', () async {
    ProcessResult result = await run(dartExecutable, ['--version']);
    expect(result.stderr.toLowerCase(), contains("dart"));
    expect(result.stderr.toLowerCase(), contains("version"));
    // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
  });
}
