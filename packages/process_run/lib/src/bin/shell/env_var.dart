import 'package:process_run/src/bin/shell/env.dart';
import 'package:process_run/src/bin/shell/env_var_delete.dart';
import 'package:process_run/src/bin/shell/env_var_dump.dart';

import 'env_var_get.dart';
import 'env_var_set.dart';
import 'import.dart';

/// Shell env var command.
class ShellEnvVarCommand extends ShellEnvCommandBase {
  /// Shell env var command.
  ShellEnvVarCommand()
    : super(
        name: commandEnvVar,
        description: 'Manipulate local and global env variables',
      ) {
    addCommand(ShellEnvVarDumpCommand());
    addCommand(ShellEnvVarSetCommand());
    addCommand(ShellEnvVarGetCommand());
    addCommand(ShellEnvVarDeleteCommand());
  }
}

/// Direct shell env var dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvVarCommand().parseAndRun(arguments);
}
