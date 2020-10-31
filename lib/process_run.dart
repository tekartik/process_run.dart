///
/// Helper to run a process and connect the input/output for verbosity
///
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process_run/src/process_run.dart';

import 'src/common/import.dart';

export 'src/dev_process_run.dart';
export 'src/process_run.dart'
    show runExecutableArguments, executableArgumentsToString;

/// Helper to run a process and connect the input/output for verbosity
///

/// Helper to run a process and connect the input/output for verbosity
///

///
/// Returns `true` if [rune] represents a whitespace character.
///
/// The definition of whitespace matches that used in [String.trim] which is
/// based on Unicode 6.2. This maybe be a different set of characters than the
/// environment's [RegExp] definition for whitespace, which is given by the
/// ECMAScript standard: http://ecma-international.org/ecma-262/5.1/#sec-15.10
///
/// from quiver
///
bool _isWhitespace(int rune) => ((rune >= 0x0009 && rune <= 0x000D) ||
    rune == 0x0020 ||
    rune == 0x0085 ||
    rune == 0x00A0 ||
    rune == 0x1680 ||
    rune == 0x180E ||
    (rune >= 0x2000 && rune <= 0x200A) ||
    rune == 0x2028 ||
    rune == 0x2029 ||
    rune == 0x202F ||
    rune == 0x205F ||
    rune == 0x3000 ||
    rune == 0xFEFF);

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
    if ((!hasWhitespace) && (_isWhitespace(rune))) {
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
