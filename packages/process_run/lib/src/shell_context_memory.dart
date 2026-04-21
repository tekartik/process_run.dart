import 'dart:convert';

import 'package:process_run/src/shell_process_result.dart';
import 'package:process_run/utils/shell_context.dart';

import '../shell.dart';

/// In memory shell context.
class ShellContextMemory with ShellContextMixin implements ShellContext {
  @override
  Encoding get encoding => utf8;

  @override
  final shellEnvironment = ShellEnvironment.empty();

  @override
  Shell shell({ShellOptions? options}) {
    return ShellMemory(context: this, options: options ?? ShellOptions());
  }

  @override
  ShellEnvironment newShellEnvironment({Map<String, String>? environment}) =>
      ShellEnvironment.empty();

  @override
  final platform = ShellContextPlatform.none();
}

/// In memory shell context.
final ShellContext shellContextMemory = ShellContextMemory();

/// Shell memory implementation.
class ShellMemory with ShellDefaultMixin, ShellMixin implements Shell {
  @override
  final ShellContextMemory context;
  @override
  final ShellOptions options;

  /// Shell memory implementation.
  ShellMemory({required this.context, required this.options});

  @override
  Future<ShellProcessResult> runCommand(
    ShellCommand command, {
    ShellCommandRunOptions? options,
  }) async {
    var executable = command.executable;
    var arguments = command.arguments;
    switch (executable) {
      case 'echo':
        var output = shellArguments(arguments);
        var result = wrapShellProcessResult(
          this,
          command,
          ProcessResult(0, 0, output, ''),
        );
        return result;
      default:
        throw UnimplementedError(
          'Command not implemented: $executable ${arguments.join(' ')}',
        );
    }
  }
}
