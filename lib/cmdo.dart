library tekartik_cmdo;

import 'dart:async';
import 'dart:convert';

/// Input command, specify at least executable
class CommandInput {
  // required
  String executable;

  // optional
  List<String> arguments;
  String workingDirectory;
  Map<String, String> environment;
  bool throwException;
  bool runInShell;
  bool connectIo;

  CommandInput._(this.executable, this.arguments,
      {this.workingDirectory,
      this.environment,
      this.runInShell,
      this.connectIo,
      this.throwException});

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(executable);
    if (arguments is List && arguments.isNotEmpty) {
      sb.write(" ${arguments}");
    }

    return sb.toString();
  }

  CommandInput clone() {
    return commandInput(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: runInShell,
        connectIo: connectIo,
        throwException: throwException);
  }
}

/// public constructor
CommandInput commandInput(String executable, List<String> arguments,
        {String workingDirectory,
        Map<String, String> environment,
        bool runInShell,
        bool connectIo,
        bool throwException}) =>
    new CommandInput._(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: runInShell,
        connectIo: connectIo,
        throwException: throwException);

/// Command output
class CommandOutput {
  var out;
  var err;
  int exitCode;
  // set internally
  var exception;

  List<String> _getLines(var output) =>
      const LineSplitter().convert(output.toString().trim());

  List<String> get outLines => _getLines(out);
  List<String> get errLines => _getLines(err);

  CommandOutput({this.exitCode, var out, var err});

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln("exitCode ${exitCode}");
    if (outLines != null && outLines.length > 0) {
      sb.writeln("> $out");
    }
    if (errLines != null && errLines.length > 0) {
      sb.writeln("ERR: ${err}");
    }
    return sb.toString();
  }
}

/// Command result, including input and output
class CommandResult {
  // in
  String get executable => input.executable;
  List<String> get arguments => input.arguments;
  String get workingDirectory => input.workingDirectory;
  Map<String, String> get environment => input.environment;
  bool get throwException => input.throwException;
  bool get runInShell => input.runInShell;
  bool get connectIo => input.connectIo;

  // out
  get out => output.out;
  get err => output.err;
  int get exitCode => output.exitCode;
  get exception => output.exception;

  final CommandInput input;
  final CommandOutput output;
  CommandResult(this.input, this.output);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln(input);
    sb.writeln(output);
    return sb.toString();
  }
}

abstract class CommandExecutor {
  Future<CommandResult> runInput(CommandInput input);
  Future<CommandResult> run(String executable, List<String> arguments,
          {String workingDirectory,
          Map<String, String> environment,
          bool runInShell,
          bool connectIo,
          bool throwException}) =>
      runInput(commandInput(executable, arguments,
          workingDirectory: workingDirectory,
          environment: environment,
          runInShell: runInShell,
          connectIo: connectIo,
          throwException: throwException));
}
