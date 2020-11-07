import 'package:process_run/src/bin/shell/env_path_dump.dart';
import 'package:process_run/src/bin/shell/env_path_prepend.dart';

import 'import.dart';

class ShellEnvPathCommand extends ShellBinCommand {
  ShellEnvPathCommand() : super(name: 'path', description: 'Path operations') {
    addCommand(ShellEnvPathDumpCommand());
    addCommand(ShellEnvPathPrependCommand());
  }
}

/// Direct shell env Path dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvPathCommand().parseAndRun(arguments);
}
