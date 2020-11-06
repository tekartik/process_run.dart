///
/// Helper to run a process and connect the input/output for verbosity
///
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process_run/src/characters.dart';
import 'package:process_run/src/process_run.dart';

import 'src/common/import.dart';

export 'src/dev_process_run.dart';
export 'src/process_run.dart'
    show runExecutableArguments, executableArgumentsToString;

/// Helper to run a process and connect the input/output for verbosity
///

/// Helper to run a process and connect the input/output for verbosity
///

/// Use to safely enclose an argument if needed
///
/// argument must not be null
String argumentToString(String argument) {
  var hasWhitespace = false;
  var singleQuoteCount = 0;
  var doubleQuoteCount = 0;
  if (argument.isEmpty) {
    return '""';
  }
  for (final rune in argument.runes) {
    if ((!hasWhitespace) && (isWhitespace(rune))) {
      hasWhitespace = true;
    } else if (rune == 0x0027) {
      // '
      singleQuoteCount++;
    } else if (rune == 0x0022) {
      // "
      doubleQuoteCount++;
    }
  }
  if (singleQuoteCount > 0) {
    if (doubleQuoteCount > 0) {
      // simply escape all double quotes
      argument = '"${argument.replaceAll('"', '\\"')}"';
    } else {
      argument = '"$argument"';
    }
  } else if (doubleQuoteCount > 0) {
    argument = "'$argument'";
  } else if (hasWhitespace) {
    argument = '"$argument"';
  }
  return argument;
}

/// Convert multiple arguments to string than can be used in a terminal
String argumentsToString(List<String> arguments) {
  final argumentStrings = <String>[];
  for (final argument in arguments) {
    argumentStrings.add(argumentToString(argument));
  }
  return argumentStrings.join(' ');
}

/// Could become deprecated.
///
/// if [commmandVerbose] or [verbose] is true, display the command.
/// if [verbose] is true, stream stdout & stdin
/// @deprecated
Future<ProcessResult> run(String executable, List<String> arguments,
        {String workingDirectory,
        Map<String, String> environment,
        bool includeParentEnvironment = true,
        bool runInShell,
        Encoding stdoutEncoding = systemEncoding,
        Encoding stderrEncoding = systemEncoding,
        Stream<List<int>> stdin,
        StreamSink<List<int>> stdout,
        StreamSink<List<int>> stderr,
        bool verbose,
        bool commandVerbose}) =>
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
