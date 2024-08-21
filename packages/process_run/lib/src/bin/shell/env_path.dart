import 'package:process_run/src/bin/shell/env_path_dump.dart';
import 'package:process_run/src/bin/shell/env_path_prepend.dart';

import 'env.dart';
import 'env_path_delete.dart';
import 'env_path_get.dart';
import 'import.dart';

/// Path operations
class ShellEnvPathCommand extends ShellEnvCommandBase {
  /// Path operations
  ShellEnvPathCommand() : super(name: 'path', description: 'Path operations') {
    addCommand(ShellEnvPathDumpCommand());
    addCommand(ShellEnvPathPrependCommand());
    addCommand(ShellEnvPathDeleteCommand());
    addCommand(ShellEnvPathGetCommand());
  }
}

/// Direct shell env Path dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvPathCommand().parseAndRun(arguments);
}
