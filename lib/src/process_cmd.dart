library process_run.src.process_cmd;

import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import '../process_run.dart';
import '../process_run.dart' as process_run;
import 'dart:async';

class ProcessCmd {
  String executable;
  List<String> arguments;
  String workingDirectory;
  Map<String, String> environment;
  bool includeParentEnvironment = true;
  bool runInShell = false;
  Encoding stdoutEncoding = SYSTEM_ENCODING;
  Encoding stderrEncoding = SYSTEM_ENCODING;
  bool connectStdout = false;
  bool connectStderr = false;
  bool connectStdin = false;

  ProcessCmd(this.executable, this.arguments,
      {this.workingDirectory,
      this.environment,
      this.includeParentEnvironment,
      this.runInShell,
      this.stdoutEncoding,
      this.stderrEncoding,
      this.connectStdin,
      this.connectStdout,
      this.connectStderr});

  ProcessCmd clone() => processCmd(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
      connectStdin: connectStdin,
      connectStdout: connectStdout,
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
      connectStdin: connectStdin,
      connectStdout: connectStdout,
      connectStderr: connectStderr);
}
