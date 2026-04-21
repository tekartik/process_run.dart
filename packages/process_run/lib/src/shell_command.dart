import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:process_run/process_run.dart';

/// Process executable arguments
class ShellCommand {
  /// Executable
  final String executable;

  /// Arguments
  final List<String> arguments;

  /// Process executable and arguments
  ShellCommand(this.executable, this.arguments);

  /// Parse a list of arguments, the first one being the executable
  ShellCommand.fromArguments(Iterable<String> arguments)
    : executable = arguments.firstOrNull ?? '',
      arguments = arguments.isEmpty ? [] : arguments.skip(1).toList();

  /// Parse a single line command
  ShellCommand.parse(String command)
    : this.fromArguments(shellScriptLineToArguments(command));

  /// Empty command
  @internal
  ShellCommand.empty() : executable = '', arguments = [];
  @override
  int get hashCode => executable.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is ShellCommand) {
      return (other.executable == executable &&
          const ListEquality<String>().equals(other.arguments, arguments));
    }
    return false;
  }

  @override
  String toString() => toCommandString();
}

/// Helpers
extension ProcessRunShellCommandExt on ShellCommand {
  /// Convert to a single line command string
  String toCommandString() =>
      executableArgumentsToString(executable, arguments);
}
