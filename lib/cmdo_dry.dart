library tekartik_cmdo.cmdo_dry;

import 'cmdo.dart' as cmdo;
import 'cmdo.dart' show CommandInput, CommandResult, CommandOutput;
export 'cmdo.dart';
import 'dart:async';

// set to true for quick debugging
bool debugCmdoDryRun = false;

class CommandExecutor implements cmdo.CommandExecutor {
  Future<CommandResult> run(CommandInput input) async {
    print(input);
    CommandResult getResult() {
      return new CommandResult(input, null);
    }
    return getResult();
  }
}
