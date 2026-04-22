@TestOn('vm')
library;

import 'package:process_run_test/echo/compile_echo.dart';
import 'package:process_run_test/echo_test.dart';
import 'package:process_run_test/src/process_run_import.dart';
import 'package:test/test.dart';

void main() async {
  late String echo;
  setUpAll(() async {
    echo = await compileEcho();
  });
  test('version', () async {
    var shell = Shell(verbose: true);
    await shell.run('$echo --version');
  });
  echoTests(EchoTestContext.lazy(() => echo));
}
