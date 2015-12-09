library process_run.src.dev_cmd_run;

import '../cmd_run.dart';
import 'dart:async';
import 'dart:io';

@deprecated
Future<ProcessResult> devRunCmd(ProcessCmd cmd) async {
  print(processCmdToDebugString(cmd));
  ProcessResult result = await runCmd(cmd);
  print(processResultToDebugString(result));
  return result;
}
