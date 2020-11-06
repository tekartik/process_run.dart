import 'dart:async';

import 'package:process_run/src/bin/shell/env_var_dump.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:process_run/src/common/import.dart';

import 'env_var_set.dart';

class ShellEnvVarCommand extends ShellCommand {
  ShellEnvVarCommand()
      : super(
            name: 'var',
            description: 'Manipulate local and global env variables') {
    addCommand(ShellEnvVarDumpCommand());
    addCommand(ShellEnvVarSetCommand());
  }
}

/// Direct shell env var dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvVarCommand().parseAndRun(arguments);
}
