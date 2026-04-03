import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:process_run/process_run.dart';
import 'package:process_run/src/io/io.dart';

/// Process command
class ProcessCmd {
  /// Process start mode
  final ProcessStartMode? mode;

  /// Executable
  String executable;

  /// Arguments
  List<String> arguments;

  /// Working directory
  String? workingDirectory;

  /// Environment
  Map<String, String>? environment;

  /// Include parent environment
  bool includeParentEnvironment;

  /// Run in shell
  bool? runInShell;

  /// Standard output encoding
  Encoding? stdoutEncoding;

  /// Standard error encoding
  Encoding? stderrEncoding;

  /// Process command
  ProcessCmd(
    this.executable,
    this.arguments, {
    this.workingDirectory,
    this.environment,
    this.includeParentEnvironment = true,
    this.runInShell,
    this.stdoutEncoding = systemEncoding,
    this.stderrEncoding = systemEncoding,
    ShellOptions? options,
    this.mode,
  });

  /// Clone
  ProcessCmd clone() => ProcessCmd(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    stdoutEncoding: stdoutEncoding,
    stderrEncoding: stderrEncoding,
    mode: mode,
  );

  @override
  int get hashCode => executable.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is ProcessCmd) {
      return (other.executable == executable &&
          const ListEquality<String>().equals(other.arguments, arguments));
    }
    return false;
  }

  @override
  String toString() => executableArgumentsToString(executable, arguments);

  /// Debug string
  String toDebugString() {
    final sb = StringBuffer();
    if (workingDirectory != null) {
      sb.writeln('dir: $workingDirectory');
    }
    sb.writeln('cmd: $this');

    return sb.toString();
  }
}

/// Standard output or error helper
bool stdIsNotEmpty(Object? stdout) {
  if (stdout is List) {
    return stdout.isNotEmpty;
  } else if (stdout is String) {
    return stdout.isNotEmpty;
  }
  return (stdout != null);
}

/// Process result debug string, compat, prefer toDebugString()
String processResultToDebugString(ProcessResult result) =>
    result.toDebugString();

/// Process command debug string, compat, prefer toDebugString()
String processCmdToDebugString(ProcessCmd cmd) => cmd.toDebugString();
