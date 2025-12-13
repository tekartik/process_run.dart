import 'package:process_run/shell.dart';
import 'package:process_run/utils/shell_context.dart';
import 'package:test/test.dart';

Future<void> main() async {
  shellCoreTests();
}

void shellCoreTests() {
  test('shell test', () async {
    print('shell context: $shellContext');
    var shell = Shell();
    var text = (await shell.run('echo Hello')).outText.trim();
    expect(text, 'Hello');
  });
  test('runZoned vars', () async {
    var env1 = ShellEnvironment()..vars['test'] = 'value1';
    var env2 = ShellEnvironment()..vars['test'] = 'value2';
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
