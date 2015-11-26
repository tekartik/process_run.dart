library tekartik_cmdo;

import 'dart:async';

// Input command, specify at least executable
class CommandInput {
  // in
  String executable;
  List<String> arguments;
  String workingDirectory;
  Map<String, String> environment;
  bool throwException;
  bool runInShell;
  bool connectIo;

  CommandInput(
      {this.executable,
      this.arguments,
      this.workingDirectory,
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
    return new CommandInput(
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: runInShell,
        connectIo: connectIo,
        throwException: throwException);
  }
}

// Output command
class CommandOutput {
  List<String> out;
  List<String> err;
  int exitCode;

  CommandOutput({this.exitCode, this.out, this.err});

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln("exitCode ${exitCode}");
    if (out != null && out.length > 0) {
      sb.writeln("> $out");
    }
    if (err != null && err.length > 0) {
      sb.writeln("ERR: ${err}");
    }
    return sb.toString();
  }
}

class CommandResult {
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
  Future<CommandResult> run(CommandInput input);
}
