library command.src.command_base;

import 'package:command/command_common.dart';
import 'dart:async';

/// Base executor
abstract class CommandExecutorMixin implements CommandExecutor {
  Future<CommandResult> run(String executable, List<String> arguments,
          {String workingDirectory,
          Map<String, String> environment,
          bool runInShell,
          bool connectIo,
          bool throwException}) =>
      runCmd(commandInput(executable, arguments,
          workingDirectory: workingDirectory,
          environment: environment,
          runInShell: runInShell,
          connectIo: connectIo,
          throwException: throwException));
}

/// convert arguments to show something similar to what is entered in the
/// command line
String argumentsToDebugString(List<String> args,
    [bool addSpaceIfNotEmpty = true]) {
  List<String> sanitized;
  if (args != null && args.isNotEmpty) {
    sanitized = [];
    for (String arg in args) {
      if (arg.contains(' ')) {
        arg = "'$arg'";
      }
      sanitized.add(arg);
    }
  } else {
    return '';
  }
  return '${addSpaceIfNotEmpty == true ? ' ' : ''}${sanitized.join(' ')}';
}
