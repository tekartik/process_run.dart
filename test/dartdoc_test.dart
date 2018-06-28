@TestOn("vm")
import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'dart:io';

import 'dart:mirrors';

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
      ProcessResult result = await runCmd(dartdocCmd(['--help']));
      expect(result.stdout, contains("Usage: dartdoc"));
      expect(result.exitCode, 0);
    });
    test('version', () async {
      ProcessResult result = await await runCmd(dartdocCmd(['--version']));
      expect(result.stdout, contains("dartdoc"));
      expect(result.exitCode, 0);
    });
    test('build', () async {
      // from dartdoc: exec "$DART" --packages="$BIN_DIR/snapshots/resources/dartdoc/.packages" "$SNAPSHOT" "$@"

      ProcessResult result = await await runCmd(
          dartdocCmd(['--output', join(testOut, joinAll(testDescriptions))]));
      //expect(result.stdout, contains("dartdoc"));
      expect(result.exitCode, 0);
      //}, skip: "failed on SDK 1.19.0"); - fixed in 1.19.1
    }, timeout: new Timeout(new Duration(minutes: 2)));
  });
}
