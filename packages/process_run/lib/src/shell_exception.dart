import 'package:process_run/shell.dart';
import 'package:process_run/src/shell_process_result.dart';

export 'shell_common.dart' show shellDebug;

/// Exception thrown in exitCode != 0 and throwOnError is true
abstract class ShellException implements Exception {
  /// Prefer
  ShellCommand? get shellCommand;

  /// Command ran if any
  /// Deprecated
  ProcessCmd? get command;

  /// Prefer
  ShellProcessResult? get shellProcessResult;

  /// Process result
  /// Deprecated
  ProcessResult? get result;

  /// Exception message
  String get message;

  /// Shell exception
  /// @deprecated
  factory ShellException(
    String msg,
    ProcessResult? result, {
    ProcessCmd? command,
  }) => _ShellException(
    message: msg,
    shellProcessResult: result?.unwrapShellProcessResult(),
    command: command,
    shellCommand: command,
  );

  /// Shell exception
  factory ShellException.process(
    String msg, {
    ShellProcessResult? result,
    // The command parsed
    ShellCommand? command,
    // The executed command
    ProcessCmd? processCmd,
  }) => _ShellException(
    message: msg,
    shellProcessResult: result,
    shellCommand: command,
    command: processCmd,
  );

  @override
  String toString() => 'ShellException($message)';

  /// Debug complete output
  String toDebugString();
}

/// Exception thrown in exitCode != 0 and throwOnError is true
class _ShellException implements ShellException {
  /// Prefer
  @override
  final ShellCommand? shellCommand;

  /// Command ran if any
  /// Deprecated
  @override
  final ProcessCmd? command;

  /// Prefer
  @override
  final ShellProcessResult? shellProcessResult;

  /// Process result
  /// Deprecated
  @override
  ProcessResult? get result => shellProcessResult?.processResult;

  /// Exception message
  @override
  final String message;

  /// Shell exception
  _ShellException({
    required this.message,
    this.shellProcessResult,
    this.command,
    this.shellCommand,
  });

  @override
  String toString() => 'ShellException($message)';

  /// Debug complete output
  @override
  String toDebugString() {
    final sb = StringBuffer();
    sb.writeln('message: $message');
    if (command != null) {
      sb.write(command!.toDebugString());
    }
    if (result != null) {
      sb.write(result!.toDebugString());
    }
    return sb.toString();
  }
}
