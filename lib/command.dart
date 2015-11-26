library command;

import 'package:command/src/command_base.dart';
import 'command_common.dart';
export 'command_common.dart';
import 'dart:async';

import 'package:command/src/command_impl.dart';

// The global executor
IoCommandExecutor ioExecutor = new IoCommandExecutor();

abstract class IoCommandExecutor extends Object
    with CommandExecutorMixin
    implements CommandExecutor {
  factory IoCommandExecutor() => new IoCommandExecutorImpl();
  IoCommandExecutor.created();
}

Future<CommandResult> runCmd(CommandInput input) => ioExecutor.runCmd(input);

/// run helper
Future<CommandResult> run(String executable, List<String> arguments,
        {String workingDirectory,
        Map<String, String> environment,
        bool runInShell,
        bool connectIo,
        bool throwException}) =>
    ioExecutor.run(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: runInShell,
        connectIo: connectIo,
        throwException: throwException);
