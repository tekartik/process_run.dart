import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

import '../process_run.dart';
import '../process_run.dart' as process_run;

class ProcessCmd {
  String executable;
  List<String> arguments;
  String workingDirectory;
  Map<String, String> environment;
  bool includeParentEnvironment;
  bool runInShell;
  Encoding stdoutEncoding;
  Encoding stderrEncoding;

  ProcessCmd(
      this.executable,
      this.arguments,
      {this.workingDirectory,
      this.environment,
      this.includeParentEnvironment: true,
      this.runInShell: false,
      this.stdoutEncoding: SYSTEM_ENCODING,
      this.stderrEncoding: SYSTEM_ENCODING});

  ProcessCmd clone() => processCmd(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding);

  @override
  int get hashCode => executable.hashCode;

  @override
  bool operator ==(o) {
    if (o is ProcessCmd) {
      return (o.executable == executable &&
          const ListEquality().equals(o.arguments, arguments));
    }
    return false;
  }

  @override
  String toString() => executableArgumentsToString(executable, arguments);

  /// Execute
  @deprecated // user runCmd instead
  Future<ProcessResult> run() => process_run.run(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding);
}

ProcessCmd processCmd(String executable, List<String> arguments,
    {String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    Encoding stdoutEncoding: SYSTEM_ENCODING,
    Encoding stderrEncoding: SYSTEM_ENCODING}) {
  return new ProcessCmd(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding);
}

String processResultToDebugString(ProcessResult result) {
  StringBuffer sb = new StringBuffer();
  sb.writeln("exitCode: ${result.exitCode}");
  if (result.stdout.isNotEmpty) {
    sb.writeln("out: ${result.stdout}");
  }
  if (result.stderr.isNotEmpty) {
    sb.writeln("err: ${result.stderr}");
  }
  return sb.toString();
}

String processCmdToDebugString(ProcessCmd cmd) {
  StringBuffer sb = new StringBuffer();
  if (cmd.workingDirectory != null) {
    sb.writeln("dir: ${cmd.workingDirectory}");
  }
  sb.writeln("cmd: ${cmd}");

  return sb.toString();
}
