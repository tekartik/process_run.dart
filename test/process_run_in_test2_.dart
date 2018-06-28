@TestOn("vm")
library process_run.process_run_in_test2_;

import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/process_run.dart';

import 'process_run_test_common.dart';

main() async {
  print('Please enter "hi"');
  ProcessResult result = await run(
    dartExecutable, [echoScriptPath, '--stdin'],
    //stdin: testStdin);
  );
  print('out: ${result.stdout}');
  print('Please enter "ho"');
  result = await run(
    dartExecutable, [echoScriptPath, '--stdin'],
    //stdin: testStdin);
  );
  print('out: ${result.stdout}');

  // unfortunately using testStdin hangs...
}
