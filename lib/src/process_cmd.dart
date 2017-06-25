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

  // now this is only a parameter at execution
  @deprecated
  bool connectStdout = false;
  @deprecated
  bool connectStderr = false;
  @deprecated
  bool connectStdin = false;

  ProcessCmd(
      this.executable,
      this.arguments,
      {this.workingDirectory,
      this.environment,
      this.includeParentEnvironment: true,
      this.runInShell: false,
      this.stdoutEncoding: SYSTEM_ENCODING,
      this.stderrEncoding: SYSTEM_ENCODING,
      @deprecated
          // ignore: deprecated_member_use
          this.connectStdin,
      @deprecated
          // ignore: deprecated_member_use
          this.connectStdout,
      @deprecated
          // ignore: deprecated_member_use
          this.connectStderr});

  ProcessCmd clone() => processCmd(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,

      // ignore: deprecated_member_use
      connectStdin: connectStdin,
      // ignore: deprecated_member_use
      connectStdout: connectStdout,
      // ignore: deprecated_member_use
      connectStderr: connectStderr);

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
      stderrEncoding: stderrEncoding,
      connectStdin: connectStdin,
      connectStdout: connectStdout,
      connectStderr: connectStderr);
}

ProcessCmd processCmd(String executable, List<String> arguments,
    {String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    Encoding stdoutEncoding: SYSTEM_ENCODING,
    Encoding stderrEncoding: SYSTEM_ENCODING,
    bool connectStdout: false,
    bool connectStderr: false,
    bool connectStdin: false}) {
  return new ProcessCmd(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
      // ignore: deprecated_member_use
      connectStdin: connectStdin,
      // ignore: deprecated_member_use
      connectStdout: connectStdout,
      // ignore: deprecated_member_use
      connectStderr: connectStderr);
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
