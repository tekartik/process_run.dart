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
String testOut = join(projectTop, 'test_out');

void main() => defineTests();

void defineTests() {
  group('dart2js', () {
    test('help', () async {
      ProcessResult result = await runCmd(dart2jsCmd(['--help']));
      expect(result.stdout, contains("Usage: dart2js"));
      expect(result.exitCode, 0);
    });
    test('version', () async {
      ProcessResult result = await await runCmd(dart2jsCmd(['--version']));
      expect(result.stdout, contains("dart2js"));
      expect(result.exitCode, 0);
    });
    test('build', () async {
      // from dart2js: exec "$DART" --packages="$BIN_DIR/snapshots/resources/dart2js/.packages" "$SNAPSHOT" "$@"

      var destination = join(testOut, joinAll(testDescriptions), 'main.js');

      // delete dir if any
      try {
        await new Directory(dirname(destination)).create(recursive: true);
      } catch (_) {}

      ProcessResult result = await await runCmd(
        dart2jsCmd(
            ['-o', destination, join(projectTop, 'test', 'data', 'main.dart')]),
        //verbose: true
      );
      //expect(result.stdout, contains("dart2js"));
      expect(result.exitCode, 0);
      //}, skip: "failed on SDK 1.19.0"); - fixed in 1.19.1
    });
  });
}
