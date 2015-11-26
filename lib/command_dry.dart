library tekartik_command.command_dry;

import 'package:command/src/command/command_base.dart';
import 'command.dart';
export 'command.dart';
import 'dart:async';

/// the dry executor
CommandExecutor dry = new DryCommandExecutor();

class DryCommandExecutor extends Object
    with CommandExecutorMixin
    implements CommandExecutor {
  Future<CommandResult> runCmd(CommandInput input) async {
    CommandOutput output = new CommandOutput(
        out: '${input.executable} ${argumentsToDebugString(input.arguments)}');
    CommandResult getResult() {
      return new CommandResult(input, output);
    }
    return getResult();
  }
}
