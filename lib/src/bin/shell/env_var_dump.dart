import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:process_run/src/utils.dart';

class ShellEnvVarDumpCommand extends ShellCommand {
  ShellEnvVarDumpCommand()
      : super(
            name: 'dump',
            description: 'Dump environment variable',
            onRun: () {
              stdout.writeln(jsonPretty(ShellEnvironment().vars));
              return true;
            });
}

/// Direct shell env var dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvVarDumpCommand().parseAndRun(arguments);
}
