@TestOn('vm')
library;

import 'package:process_run_test/echo/compile_echo.dart';
import 'package:process_run_test/echo_test.dart';
import 'package:test/test.dart';

void main() async {
  var echoExecutable = await compileEcho();
  echoTests(EchoTestContext(echoExecutable));
}
