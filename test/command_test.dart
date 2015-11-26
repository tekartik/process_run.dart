@TestOn("vm")
library command.test.command_test;

import 'test_common_io.dart';
import 'command_test_.dart' as _test;
import 'package:command/dartbin.dart';
import 'package:command/src/command_impl.dart';
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

runCmdAsync(CommandInput input) =>
    (ioExecutor as IoCommandExecutorImpl).runCmdAsync(input);
void main() {
  //_io.debugCommand = true;
  group('io', () {
    exampleCmd(List<String> arguments) {
      return dartCmd(new List.from(arguments)
        ..insert(0, join(testDir, 'command_example.dart')));
    }
    _test.defineTests(ioExecutor);

    test('example', () async {
      CommandResult result = await ioExecutor.runCmd(exampleCmd([]));
      expect(result.out, "");
      expect(result.err, "");
      expect(result.output.outLines, []);
      expect(result.output.errLines, []);
      expect(result.exitCode, 0);

      result = await runCmdAsync(exampleCmd([]));
      expect(result.out, "");
      expect(result.err, "");
      expect(result.output.outLines, []);
      expect(result.output.errLines, []);
      expect(result.exitCode, 0);

      result = await ioExecutor.runCmd(exampleCmd(["out", "err", "1"]));
      expect(result.output.outLines, ["out"]);
      expect(result.output.errLines, ["err"]);
      expect(result.exitCode, 1);

      result = await runCmdAsync(exampleCmd(["out", "err", "1"]));
      expect(result.output.outLines, ["out"]);
      expect(result.output.errLines, ["err"]);
      expect(result.exitCode, 1);
    });

    test('system_command', () async {
      // use 'cat' on mac and linux
      // use 'type' on windows
      if (Platform.isMacOS || Platform.isLinux) {
        CommandResult result = await ioExecutor.run('cat', ['pubspec.yaml'],
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
          await runCmdAsync(testCommandThrows.clone());
        } catch (e) {
          err = e;
        }
        expect(err, isNotNull);
      });

      test('nothrow bad exe', () async {
        CommandResult result = await runCmdAsync(
            testCommandThrows.clone()..throwException = false);

        expect(result.err, isNull);
        expect(result.out, isNull);
        expect(result.exitCode, isNull);
        expect(result.exception, isNotNull);
      });

      test('dart_version', () async {
        CommandInput input = command(dartVmBin, ['--version']);
        CommandResult result = await ioExecutor.runCmd(input);
        expect(result.output.errLines.first.toLowerCase(), contains("dart"));
        expect(result.output.errLines.first.toLowerCase(), contains("version"));

        result = await runCmdAsync(input);
        expect(result.output.errLines.first.toLowerCase(), contains("dart"));
        expect(result.output.errLines.first.toLowerCase(), contains("version"));
      });
    });
  });
}
