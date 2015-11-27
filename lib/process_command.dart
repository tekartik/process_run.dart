library process_command;

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'process_run.dart';

class ProcessCommand {
  // required
  String executable;
  List<String> arguments;

  // optional
  String workingDirectory;
  Map<String, String> environment;
  bool throwException;
  bool includeParentEnvironment; //true
  bool runInShell; // false
  Encoding stdoutEncoding; // SYSTEM_ENCODING
  Encoding stderrEncoding; // SYSTEM_ENCODING

  /// extra paremeter
  /// if true will pipe stdin and stderr
  bool connectStdout; // false
  bool connectStderr; // false
  bool connectStdin; // false

  ProcessCommand._(this.executable, this.arguments,
      {this.workingDirectory,
      this.environment,
      this.includeParentEnvironment: true,
      this.runInShell: false,
      this.stdoutEncoding: SYSTEM_ENCODING,
      this.stderrEncoding: SYSTEM_ENCODING,
      this.connectStdout: false,
      this.connectStderr: false,
      this.connectStdin: false});

  @override
  String toString() => executableArgumentsToString(executable, arguments);

  ProcessCommand clone() {
    return command(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding,
        connectStdout: connectStdout,
        connectStderr: connectStderr,
        connectStdin: connectStdin);
  }
}

/// public constructor
ProcessCommand command(String executable, List<String> arguments,
        {String workingDirectory,
        Map<String, String> environment,
        includeParentEnvironment: true,
        bool runInShell: false,
        stdoutEncoding: SYSTEM_ENCODING,
        stderrEncoding: SYSTEM_ENCODING,
        connectStdout: false,
        connectStderr: false,
        connectStdin: false}) =>
    new ProcessCommand._(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding,
        connectStdout: connectStdout,
        connectStderr: connectStderr,
        connectStdin: connectStdin);

Future<ProcessResult> runCommand(ProcessCommand command) =>
    run(command.executable, command.arguments,
        workingDirectory: command.workingDirectory,
        environment: command.environment,
        includeParentEnvironment: command.includeParentEnvironment,
        runInShell: command.runInShell,
        stdoutEncoding: command.stdoutEncoding,
        stderrEncoding: command.stderrEncoding,
        connectStdout: command.connectStdout,
        connectStderr: command.connectStderr,
        connectStdin: command.connectStdin);
