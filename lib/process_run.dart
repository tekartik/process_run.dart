///
/// Helper to run a process and connect the input/output for verbosity
///
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process_run/src/process_run.dart';

import 'src/common/import.dart';

export 'package:process_run/src/shell_utils_common.dart'
    show argumentsToString, argumentToString;

export 'src/dev_process_run.dart';
export 'src/process_run.dart'
    show runExecutableArguments, executableArgumentsToString;

/// Use runExecutableArguments instead
///
/// if [commmandVerbose] or [verbose] is true, display the command.
/// if [verbose] is true, stream stdout & stdin
@Deprecated('Use runExecutableArguments instead')
Future<ProcessResult> run(String executable, List<String> arguments,
        {String? workingDirectory,
        Map<String, String>? environment,
        bool includeParentEnvironment = true,
        bool? runInShell,
        Encoding? stdoutEncoding = systemEncoding,
        Encoding? stderrEncoding = systemEncoding,
        Stream<List<int>>? stdin,
        StreamSink<List<int>>? stdout,
        StreamSink<List<int>>? stderr,
        bool? verbose,
        bool? commandVerbose}) =>
    runExecutableArguments(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stderrEncoding: stderrEncoding,
      stdoutEncoding: stdoutEncoding,
      stdin: stdin,
      stdout: stdout,
      stderr: stderr,
      verbose: verbose,
      commandVerbose: commandVerbose,
    );
