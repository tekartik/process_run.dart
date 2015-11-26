library tekartik_cmdo.cmdo_dry;

import 'package:cmdo/src/cmdo/cmdo_base.dart';
import 'cmdo.dart';
export 'cmdo.dart';
import 'dart:async';

/// the dry executor
CommandExecutor dry = new DryCommandExecutor();

class DryCommandExecutor extends Object
    with CommandExecutorMixin
    implements CommandExecutor {
  Future<CommandResult> runInput(CommandInput input) async {
    CommandOutput output = new CommandOutput(
        out: '${input.executable} ${argumentsToDebugString(input.arguments)}');
    CommandResult getResult() {
      return new CommandResult(input, output);
    }
    return getResult();
  }
}
