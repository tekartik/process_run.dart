@TestOn('vm')
library;

import 'package:process_run_test/echo/compile_echo.dart';
import 'package:process_run_test/echo_test.dart';
import 'package:test/test.dart';

void main() async {
  late String echo;
  setUpAll(() async {
    echo = await compileEcho();
  });
  echoTests(EchoTestContext.lazy(() => echo));
}
