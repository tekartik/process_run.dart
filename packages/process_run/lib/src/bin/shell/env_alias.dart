import 'package:process_run/src/bin/shell/env_alias_dump.dart';
import 'package:process_run/src/bin/shell/env_alias_set.dart';

import 'env_alias_delete.dart';
import 'env_alias_get.dart';
import 'import.dart';

/// Alias operations
class ShellEnvAliasCommand extends ShellBinCommand {
  /// Alias operations
  ShellEnvAliasCommand()
    : super(name: commandEnvAliases, description: 'Alias operations') {
    addCommand(ShellEnvAliasDumpCommand());
    addCommand(ShellEnvAliasSetCommand());
    addCommand(ShellEnvAliasGetCommand());
    addCommand(ShellEnvAliasDeleteCommand());
  }
}

/// Direct shell env Alias dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvAliasCommand().parseAndRun(arguments);
}
