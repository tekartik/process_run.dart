import 'package:process_run/src/bin/shell/env_alias_dump.dart';
import 'package:process_run/src/bin/shell/env_alias_set.dart';
import 'package:process_run/src/bin/shell/shell.dart';

class ShellEnvAliasCommand extends ShellCommand {
  ShellEnvAliasCommand()
      : super(name: 'alias', description: 'Alias operations') {
    addCommand(ShellEnvAliasDumpCommand());
    addCommand(ShellEnvAliasSetCommand());
  }
}

/// Direct shell env Alias dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvAliasCommand().parseAndRun(arguments);
}
