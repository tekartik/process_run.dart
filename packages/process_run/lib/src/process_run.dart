import 'dart:convert';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/io/io.dart' as io;
import 'package:process_run/src/io/io.dart';

import 'common/import.dart';

export 'shell_utils_io.dart' show executableArgumentsToString;

///
/// if [commandVerbose] or [verbose] is true, display the command.
/// if [verbose] is true, stream stdout & stdin
///
/// Optional [onProcess(process)] is called to allow killing the process.
///
/// If [noStdoutResult] is true, the result will not contain the stdout.
/// If [noStderrResult] is true, the result will not contain the stderr.
///
/// Don't mess-up with the input and output for now here. only use it for kill.
Future<ProcessResult> runExecutableArguments(
  String executable,
  List<String> arguments, {

  /// Prefer options, or even better, use a shell...
  ShellOptions? options,
  // follwing To deprecate
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool? runInShell,
  Encoding? stdoutEncoding = systemEncoding,
  Encoding? stderrEncoding = systemEncoding,
  Stream<List<int>>? stdin,
  StreamSink<List<int>>? stdout,
  StreamSink<List<int>>? stderr,
  bool? verbose,
  bool? commandVerbose,
  bool? noStdoutResult,
  bool? noStderrResult,
  ShellOnProcessCallback? onProcess,
  ProcessStartMode? mode,

  /// Compat default to false...
  bool? throwOnError,
}) async {
  throwOnError ??= false;
  options ??= ShellOptions(
    verbose: verbose ?? false,
    commandVerbose: commandVerbose,
    stderrEncoding: stderrEncoding,
    stdoutEncoding: stdoutEncoding,
    workingDirectory: workingDirectory,
    stdout: stdout,
    stderr: stderr,
    stdin: stdin,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    mode: mode,
    noStderrResult: noStderrResult,
    noStdoutResult: noStdoutResult,
    throwOnError: throwOnError,
  );
  var shell = Shell(options: options);
  var result = await shell.runExecutableArguments(
    executable,
    arguments,
    onProcess: onProcess,
  );
  return result;
}

///
/// if [commandVerbose] or [verbose] is true, display the command.
/// if [verbose] is true, stream stdout & stdin
///
/// Does not throw by default if no options are given.
///
/// Compared to the async version, it is not possible to kill the spawn process nor to
/// feed any input.
ProcessResult runExecutableArgumentsSync(
  String executable,
  List<String> arguments, {

  /// Prefer options
  ShellOptions? options,
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool? runInShell,
  Encoding? stdoutEncoding = systemEncoding,
  Encoding? stderrEncoding = systemEncoding,
  StreamSink<List<int>>? stdout,
  StreamSink<List<int>>? stderr,
  bool? verbose,
  bool? commandVerbose,

  /// Compat default to false
  bool? throwOnError,
}) {
  throwOnError ??= false;
  options ??= ShellOptions(
    verbose: verbose ?? false,
    commandVerbose: commandVerbose,
    stderrEncoding: stderrEncoding,
    stdoutEncoding: stdoutEncoding,
    workingDirectory: workingDirectory,
    stdout: stdout,
    stderr: stderr,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    throwOnError: false,
  );
  var result = Shell(
    options: options,
  ).runExecutableArgumentsSync(executable, arguments);

  return result;
}

/// Command runner. not exported

/// Execute a predefined ProcessCmd command
///
/// if [commandVerbose] is true, it writes the command line executed preceeded by $ to stdout. It streams
/// stdout/error if [verbose] is true.
/// [verbose] implies [commandVerbose]
///
Future<ProcessResult> processCmdRun(
  ProcessCmd cmd, {
  ShellOptions? options,
  bool? verbose,
  bool? commandVerbose,
  Stream<List<int>>? stdin,
  StreamSink<List<int>>? stdout,
  StreamSink<List<int>>? stderr,
  bool? noStdoutResult,
  bool? noStderrResult,
  ShellOnProcessCallback? onProcess,
}) async {
  options ??= ShellOptions(
    verbose: verbose ?? false,
    commandVerbose: commandVerbose,
    stderrEncoding: cmd.stderrEncoding,
    stdoutEncoding: cmd.stdoutEncoding,
    workingDirectory: cmd.workingDirectory,
    stdin: stdin,
    stdout: stdout,
    stderr: stderr,
    environment: cmd.environment,
    includeParentEnvironment: cmd.includeParentEnvironment,
    runInShell: cmd.runInShell,
    mode: cmd.mode,
  );
  var shell = Shell(options: options);
  var command = ShellCommand(cmd.executable, cmd.arguments);

  return (await shell.runCommand(
    command,
    options: ShellCommandRunOptions(onProcess: onProcess),
  )).processResult;
}

/// Dump the exception to stderr
void dumpException({
  // Executed command
  required ShellCommand command,
  required Object exception,
  String? workingDirectory,
}) {
  io.stderr.writeln(exception);
  io.stderr.writeln('\$ ${command.toCommandString()}');
  io.stderr.writeln(
    'workingDirectory: ${normalize(absolute(workingDirectory ?? Directory.current.path))}',
  );
}
