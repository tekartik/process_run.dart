library process_run.src.dev_cmd_run;

import '../cmd_run.dart';
import 'dart:async';
import 'dart:io';

@deprecated
Future<ProcessResult> devRunCmd(ProcessCmd cmd) async {
  return runCmd(cmd, verbose: true);
}
