import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';

import 'common/import.dart';

/// Run a command in the current working directory
Future<List<ProcessResult>> run(String script,
    {bool throwOnError = true,
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
    Stream<List<int>> stdin,
    StreamSink<List<int>> stdout,
    StreamSink<List<int>> stderr,
    bool verbose = true,
    // Default to true
    bool commandVerbose,
    // Default to true if verbose is true
    bool commentVerbose}) {
  return Shell(
          throwOnError: throwOnError,
          workingDirectory: workingDirectory,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment,
          runInShell: runInShell,
          stdoutEncoding: stdoutEncoding,
          stderrEncoding: stderrEncoding,
          stdin: stdin,
          stdout: stdout,
          stderr: stderr,
          verbose: verbose,
          commandVerbose: commandVerbose,
          commentVerbose: commentVerbose)
      .run(script);
}
