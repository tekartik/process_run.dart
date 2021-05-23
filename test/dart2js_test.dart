@TestOn('vm')
library process_run.dart2js_test;

import 'dart:io';
import 'dart:mirrors';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

String getScriptPath(Type type) =>
    (reflectClass(type).owner as LibraryMirror).uri.toFilePath();

class Script {
  static String get path => getScriptPath(Script);
}

String projectTop = dirname(dirname(Script.path));
String testOut = join(projectTop, 'test_out');

void main() => defineTests();

void defineTests() {
  group('dart2js', () {
    test('help', () async {
      final result = await runCmd(Dart2JsCmd(['--help']));
      expect(result.stdout, contains('Usage: dart2js'));
      expect(result.exitCode, 0);
    });
    test('version', () async {
      final result = await runCmd(Dart2JsCmd(['--version']));
      expect(result.stdout, contains('dart2js'));
      expect(result.exitCode, 0);
    });
    test('build', () async {
      // from dart2js: exec '$DART' --packages='$BIN_DIR/snapshots/resources/dart2js/.packages' '$SNAPSHOT' '$@'

      var destination = join(testOut, 'dart2js_build', 'main.js');

      // delete dir if any
      try {
        await Directory(dirname(destination)).create(recursive: true);
      } catch (_) {}

      final result = await runCmd(
        Dart2JsCmd(
            ['-o', destination, join(projectTop, 'test', 'data', 'main.dart')]),
        //verbose: true
      );
      //expect(result.stdout, contains('dart2js'));
      expect(result.exitCode, 0);
      //}, skip: 'failed on SDK 1.19.0'); - fixed in 1.19.1
    });
  });
}
