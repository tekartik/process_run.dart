import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:process_run/process_run.dart';
import 'package:process_run/src/io/io.dart';

/// Process command
class ProcessCmd {
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
}

bool _isNotEmpty(Object? stdout) {
  if (stdout is List) {
    return stdout.isNotEmpty;
  } else if (stdout is String) {
    return stdout.isNotEmpty;
  }
  return (stdout != null);
}

/// Process result debug string
String processResultToDebugString(ProcessResult result) {
  final sb = StringBuffer();
  sb.writeln('exitCode: ${result.exitCode}');
  if (_isNotEmpty(result.stdout)) {
    sb.writeln('out: ${result.stdout}');
  }
  if (_isNotEmpty(result.stderr)) {
    sb.writeln('err: ${result.stderr}');
  }
  return sb.toString();
}

/// Process command debug string
String processCmdToDebugString(ProcessCmd cmd) {
  final sb = StringBuffer();
  if (cmd.workingDirectory != null) {
    sb.writeln('dir: ${cmd.workingDirectory}');
  }
  sb.writeln('cmd: $cmd');

  return sb.toString();
}
