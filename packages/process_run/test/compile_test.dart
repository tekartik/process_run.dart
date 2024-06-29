@TestOn('vm')
library process_run_test_windows_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

import 'src/compile_echo.dart';

void main() {
  test('compile and run exe', () async {
    var echoExePath = await compileEchoExample();
    var echoExeDir = dirname(echoExePath);
    var echoExeName = basename(echoExePath);

    // Try path access
    var lines = (await Shell(verbose: false)
            .run('${shellArgument(echoExePath)} --stdout test'))
        .outLines;
    expect(lines, ['test']);

    // Try using alias
    lines = (await Shell(
                verbose: false,
                environment: ShellEnvironment()..aliases['echo'] = echoExePath)
            .run('echo --stdout test'))
        .outLines;
    expect(lines, ['test']);

    // Try using alias in options
    var options = ShellOptions(
        verbose: false,
        environment: ShellEnvironment()..aliases['echo'] = echoExePath);
    lines = (await Shell(options: options).run('echo --stdout test')).outLines;
    expect(lines, ['test']);
    // Try using alias
    lines = (await Shell(
                verbose: false,
                environment: ShellEnvironment()..aliases['echo'] = echoExePath)
            .run('''
echo --stdout test1
echo --stdout test2
        '''))
        .outLines;
    expect(lines, ['test1', 'test2']);

    // Try relative access
    var exePathShell = Shell(workingDirectory: echoExeDir, verbose: false);
    lines = (await exePathShell
            .run('${shellArgument(join('.', echoExeName))} --stdout test'))
        .outLines;
    expect(lines, ['test']);

    // Without using a relative path, this should fail
    try {
      await exePathShell.run('${shellArgument(echoExeName)} --stdout test');
      fail('should fail');
    } on ShellException catch (_) {
      // print(e);
    }

    expect(lines, ['test']);
  },
      skip: !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
      timeout: const Timeout(Duration(minutes: 10)));
}
