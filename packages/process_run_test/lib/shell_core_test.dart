import 'package:process_run/shell.dart';
// ignore: implementation_imports
import 'package:process_run/utils/process_result_extension.dart';
import 'package:process_run/utils/shell_context.dart';
import 'package:test/test.dart';

Future<void> main() async {
  shellCoreTests(ShellContextMemory());
}

/// shell core tests
void shellCoreTests(ShellContext shellContext) {
  test('shell echo command test', () async {
    var shell = shellContext.shell();
    var command = ShellCommand.parse('echo Hello');
    var processResult = await shell.runCommand(command);
    var text = processResult.outText.trim();
    expect(text, 'Hello');
    expect(
      processResult.processExecutableArguments,
      ShellCommand('echo', ['Hello']),
    );
  });
  test('shell echo script test', () async {
    var shell = shellContext.shell();

    var processResults = await shell.runScript('echo Hello');
    var text = processResults.outText.trim();
    var processResult = processResults.first;

    expect(text, 'Hello');
    expect(
      processResult.processExecutableArguments,
      ShellCommand('echo', ['Hello']),
    );
  });

  // multi platform even memory!
  test('shell echo test', () async {
    var shell = shellContext.shell();
    var processResults = await shell.run('echo Hello');
    var text = processResults.outText.trim();
    expect(text, 'Hello');
    var processResult = processResults.first;
    expect(processResult.isShellProcessResult, isTrue);
    expect(
      processResult.processExecutableArguments,
      ShellCommand('echo', ['Hello']),
    );

    processResult = processResults.first;
    expect(processResult.isShellProcessResult, isTrue);
    expect(
      processResult.processExecutableArguments,
      ShellCommand('echo', ['Hello']),
    );
  });
  test('runZoned vars', () async {
    var env1 = shellContext.newShellEnvironment()..vars['test'] = 'value1';
    var env2 = shellContext.newShellEnvironment()..vars['test'] = 'value2';
    var ctx1 = shellContext.copyWith(shellEnvironment: env1);
    var ctx2 = shellContext.copyWith(shellEnvironment: env2);
    Future<void> testEnv(String expected) async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        var readVar = ShellEnvironment().vars['test'];
        expect(readVar, expected);
      }
    }

    var future1 = ctx1.runZoned(() async {
      await testEnv('value1');
    });
    var future2 = ctx2.runZoned(() async {
      await testEnv('value2');
    });
    await Future.wait([future1, future2]);
  });
}
