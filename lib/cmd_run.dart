///
/// Command runner
///

import 'dart:async';
import 'dart:io';
import 'dart:io' as io;

import 'process_run.dart';
import 'src/process_cmd.dart';

export 'dartbin.dart';
export 'process_run.dart';
export 'src/dartbin_cmd.dart';
export 'src/dev_cmd_run.dart';
export 'src/process_cmd.dart';

///
/// Execute a predefined ProcessCmd command
///
/// if [commandVerbose] is true, it writes the command line executed preceeded by $ to stdout. It streams
/// stdout if [stdoutVerbose] is true and stderr if [stderrVerbose] is true.
/// [verbose] is a shortcut for specifying true for [commandVerbose], [stdoutVerbose], [stderrVerbose]
///
Future<ProcessResult> runCmd(ProcessCmd cmd,
    {bool verbose,
    bool commandVerbose,
    Stream<List<int>> stdin,
    StreamSink<List<int>> stdout,
    StreamSink<List<int>> stderr}) async {
  // compatibility 0.4.0
  // ignore: deprecated_member_use
  if (cmd.connectStdin == true) {
    stdin ??= io.stdin;
  }
  // ignore: deprecated_member_use
  if (cmd.connectStderr == true) {
    stderr ??= io.stderr;
  }
  // ignore: deprecated_member_use
  if (cmd.connectStdout == true) {
    stdout ??= io.stdout;
  }

  if (verbose == true) {
    stdout ??= io.stdout;
    stderr ??= io.stderr;
    commandVerbose = true;
  }

  if (commandVerbose == true) {
    (stdout ?? io.stdout).add("\$ ${cmd}\n".codeUnits);
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
      io.stderr.writeln("\$ ${cmd}");
      io.stderr.writeln("workingDirectory: ${cmd.workingDirectory}");
    }
    rethrow;
  }
}
