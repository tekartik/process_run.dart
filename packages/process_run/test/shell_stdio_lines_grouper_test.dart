@TestOn('vm')
library;

import 'package:process_run/process_run.dart';
import 'package:process_run/stdio.dart';
import 'package:test/test.dart';

import 'src/compile_echo.dart';

void main() {
  group('shell_stdio_lines_grouper', () {
    test('hello123', () async {
      var echo = await compileEchoExample();

      var options = ShellOptions(
          verbose: false,
          environment: ShellEnvironment()..aliases['echo'] = echo);
      var lines =
          (await Shell(options: options).run('echo --stdout test')).outLines;
      expect(lines, ['test']);
      /*
      var env = ShellEnvironment()
        // ..aliases['echo'] = 'dart run ${shellArgument(echoScriptPath)}';
        ..aliases['echo'] = echo;

      var options = ShellOptions(environment: env);
      */
      var shell = Shell(options: options);

      await shell.run('echo --stdout hello1');

      /*
      var options = ShellOptions(verbose: true, environment: env);
      */
      Future<List<ProcessResult>> printHello123Slow() async {
        var shell = Shell(options: options);
        return await shell.run('''
echo --wait 100 --stdout hello1
echo --wait 100 --stdout hello2
''');
      }

      // await printHello123Slow();

      var stdio = shellStdioLinesGrouper;
      await Future.wait<List<ProcessResult>>(
          [stdio.runZoned(() => printHello123Slow()), printHello123Slow()]);
    });
    test('ok', () {});
  });
}
