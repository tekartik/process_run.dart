import 'package:process_run/shell.dart';

export 'shell_common.dart' show shellDebug;

/// Exception thrown in exitCode != 0 and throwOnError is true
class ShellException implements Exception {
  /// Command ran if any
  final ProcessCmd? command;

  /// Process result
  final ProcessResult? result;

  /// Exception message
  final String message;

  /// Shell exception
  ShellException(this.message, this.result, {this.command});

  @override
  String toString() => 'ShellException($message)';

  /// Debug complete output
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
