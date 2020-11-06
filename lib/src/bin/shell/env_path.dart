import 'package:process_run/src/bin/shell/env_path_dump.dart';
import 'package:process_run/src/bin/shell/shell.dart';

class ShellEnvPathCommand extends ShellCommand {
  ShellEnvPathCommand() : super(name: 'Path', description: 'Path operations') {
    addCommand(ShellEnvPathDumpCommand());
  }
}

/// Direct shell env Path dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvPathCommand().parseAndRun(arguments);
}
