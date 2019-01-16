@TestOn("vm")
library process_run.dartdoc_test;

import 'dart:io';
import 'dart:mirrors';

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';

String getScriptPath(Type type) =>
    (reflectClass(type).owner as LibraryMirror).uri.toFilePath();

class Script {
  static String get path => getScriptPath(Script);
}

String projectTop = dirname(dirname(Script.path));
String testOut = join(projectTop, '.dart_tool', 'process_run', 'test');

void main() => defineTests();

void defineTests() {
  group('dartdoc', () {
    test('help', () async {
      ProcessResult result = await runCmd(DartDocCmd(['--help']));
      expect(result.stdout, contains("--version"));
      expect(result.exitCode, 0);
    });
    test('version', () async {
      ProcessResult result = await runCmd(DartDocCmd(['--version']));
      expect(result.stdout, contains("dartdoc"));
      expect(result.exitCode, 0);
    });
    test('build', () async {
      // from dartdoc: exec "$DART" --packages="$BIN_DIR/snapshots/resources/dartdoc/.packages" "$SNAPSHOT" "$@"

      ProcessResult result = await runCmd(
          DartDocCmd(['--output', join(testOut, joinAll(testDescriptions))]));
      //expect(result.stdout, contains("dartdoc"));
      expect(result.exitCode, 0);
      //}, skip: "failed on SDK 1.19.0"); - fixed in 1.19.1
    }, timeout: Timeout(Duration(minutes: 2)));
  });
}
