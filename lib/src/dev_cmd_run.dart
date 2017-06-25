import 'dart:async';
import 'dart:io';

import '../cmd_run.dart';

@deprecated
Future<ProcessResult> devRunCmd(ProcessCmd cmd,
    {bool verbose,
    bool commandVerbose,
    Stream<List<int>> stdin,
    StreamSink<List<int>> stdout,
    StreamSink<List<int>> stderr}) async {
  return runCmd(cmd,
      verbose: true,
      commandVerbose: commandVerbose,
      stdin: stdin,
      stderr: stderr);
}
