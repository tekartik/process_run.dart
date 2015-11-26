@TestOn("vm")
library tekartik_cmdo.test.cmdo_io_test;

import 'cmdo_io_test_common.dart';
import 'cmdo_test_.dart' as _test;
import 'package:cmdo/dartbin.dart';
import 'dart:mirrors';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;
String get testDir => dirname(testScriptPath);

void main() {
  //_io.debugCmdoIo = true;
  group('io', () {
    exampleCmd(List<String> arguments) {
      return dartCmd(new List.from(arguments)
        ..insert(0, join(testDir, 'cmdo_example.dart')));
    }
    _test.defineTests(io);

    test('example', () async {
      CommandResult result = await io.runCmd(exampleCmd([]));
      expect(result.out, "");
      expect(result.err, "");
      expect(result.output.outLines, []);
      expect(result.output.errLines, []);
      expect(result.exitCode, 0);

      result = await io.runCmdAsync(exampleCmd([]));
      expect(result.out, "");
      expect(result.err, "");
      expect(result.output.outLines, []);
      expect(result.output.errLines, []);
      expect(result.exitCode, 0);

      result = await io.runCmd(exampleCmd(["out", "err", "1"]));
      expect(result.output.outLines, ["out"]);
      expect(result.output.errLines, ["err"]);
      expect(result.exitCode, 1);

      result = await io.runCmdAsync(exampleCmd(["out", "err", "1"]));
      expect(result.output.outLines, ["out"]);
      expect(result.output.errLines, ["err"]);
      expect(result.exitCode, 1);
    });

    test('system_command', () async {
      // use 'cat' on mac and linux
      // use 'type' on windows
      if (Platform.isMacOS || Platform.isLinux) {
        CommandResult result = await io.run('cat', ['pubspec.yaml'],
            workingDirectory: dirname(testDir));

        // read pubspec.yaml
        List<String> lines = const LineSplitter().convert(
            await new File(join(dirname(testDir), 'pubspec.yaml'))
                .readAsString());

        expect(result.output.outLines, lines);
      }
    });

    group('async', () {
      test('throw bad exe', () async {
        var err;
        try {
          await io.runCmdAsync(testCommandThrows.clone());
        } catch (e) {
          err = e;
        }
        expect(err, isNotNull);
      });

      test('nothrow bad exe', () async {
        CommandResult result = await io
            .runCmdAsync(testCommandThrows.clone()..throwException = false);

        expect(result.err, isNull);
        expect(result.out, isNull);
        expect(result.exitCode, isNull);
        expect(result.exception, isNotNull);
      });

      test('dart_version', () async {
        CommandInput input = commandInput(dartVmBin, ['--version']);
        CommandResult result = await io.runCmd(input);
        expect(result.output.errLines.first.toLowerCase(), contains("dart"));
        expect(result.output.errLines.first.toLowerCase(), contains("version"));

        result = await io.runCmdAsync(input);
        expect(result.output.errLines.first.toLowerCase(), contains("dart"));
        expect(result.output.errLines.first.toLowerCase(), contains("version"));
      });
    });
  });
}
