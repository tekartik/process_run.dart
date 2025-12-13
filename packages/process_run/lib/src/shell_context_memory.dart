import 'dart:convert';
import 'dart:io' show ProcessResult;

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
  Future<ProcessResult> runExecutableArguments(
    String executable,
    List<String> arguments, {
    ShellOnProcessCallback? onProcess,
  }) async {
    switch (executable) {
      case 'echo':
        var output = '${arguments.join(' ')}\n';
        return ProcessResult(0, 0, output, '');
      default:
        throw UnimplementedError(
          'Command not implemented: $executable ${arguments.join(' ')}',
        );
    }
  }
}
