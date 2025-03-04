// ignore_for_file: avoid_print

@TestOn('vm')
library;

import 'package:process_run/shell.dart';
import 'package:test/test.dart';

import 'src/compile_echo.dart';

Future<void> main() async {
  var echo = await compileEchoExample();

  var env = ShellEnvironment()..aliases['echo'] = echo;

  group('ShellZoned', () {
    test('runZoned', () async {
      var varName = 'PROCESS_RUN_VAR_ZONED_TEST';
      var env1 = ShellEnvironment(environment: env)..vars[varName] = 'value1';
      var env2 = ShellEnvironment(environment: env)..vars[varName] = 'value2';
      Future<void> testEnv(String expected) async {
        for (var i = 0; i < 10; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 1));

          var readVar = ShellEnvironment().vars[varName];
          print('$readVar vs $expected');
          expect(readVar, expected);
        }
        var output = (await run('echo --stdout-env $varName')).outText.trim();
        expect(output, expected);
      }

      var future1 = env1.runZoned(() async {
        await testEnv('value1');
      });
      var future2 = env2.runZoned(() async {
        await testEnv('value2');
      });
      await Future.wait([future1, future2]);

      //var env1 = ShellEnvironment().runZoned()
    });
  });
}
