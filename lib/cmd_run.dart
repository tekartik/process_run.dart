///
/// Command runner
///

import 'dart:async';
import 'dart:io';
import 'dart:io' as io;

import 'package:process_run/src/shell_utils.dart';

import 'process_run.dart';
import 'src/process_cmd.dart';

export 'dartbin.dart';
export 'dartbin.dart'
    show
        getFlutterBinVersion,
        getFlutterBinChannel,
        isFlutterSupported,
        isFlutterSupportedSync;
export 'process_run.dart';
export 'src/build_runner.dart';
export 'src/dartbin_cmd.dart' hide parsePlatformVersion;
export 'src/dev_cmd_run.dart';
export 'src/flutterbin_cmd.dart' show flutterExecutablePath, FlutterCmd;
export 'src/process_cmd.dart';
export 'src/webdev.dart';

/// Command runner
///

///
/// Execute a predefined ProcessCmd command
///
/// if [commandVerbose] is true, it writes the command line executed preceeded by $ to stdout. It streams
/// stdout/error if [verbose] is true.
/// [verbose] implies [commandVerbose]
///
Future<ProcessResult> runCmd(ProcessCmd cmd,
    {bool verbose,
    bool commandVerbose,
    Stream<List<int>> stdin,
    StreamSink<List<int>> stdout,
    StreamSink<List<int>> stderr}) async {
  if (verbose == true) {
    stdout ??= io.stdout;
    stderr ??= io.stderr;
    commandVerbose ??= true;
  }

  if (commandVerbose == true) {
    streamSinkWriteln(stdout ?? io.stdout, '\$ ${cmd}');
  }

  try {
    return await run(
      cmd.executable,
      cmd.arguments,
      workingDirectory: cmd.workingDirectory,
      environment: cmd.environment,
      includeParentEnvironment: cmd.includeParentEnvironment,
      runInShell: cmd.runInShell,
      stdoutEncoding: cmd.stdoutEncoding,
      stderrEncoding: cmd.stderrEncoding,
      //verbose: verbose,
      //commandVerbose: commandVerbose,
      stdin: stdin,
      stdout: stdout,
      stderr: stderr,
    );
  } catch (e) {
    if (verbose == true) {
      io.stderr.writeln(e);
      io.stderr.writeln('\$ ${cmd}');
      io.stderr.writeln(
          'workingDirectory: ${cmd.workingDirectory ?? Directory.current?.path}');
    }
    rethrow;
  }
}
