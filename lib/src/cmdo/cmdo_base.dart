library tekartik_cmdo.src.cmdo.cmdo_base;

import 'package:cmdo/cmdo.dart';
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

  @deprecated
  Future<CommandResult> runInput(CommandInput input) => runCmd(input);
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
