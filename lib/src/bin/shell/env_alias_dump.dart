import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/utils.dart';

class ShellEnvAliasDumpCommand extends ShellCommand {
  ShellEnvAliasDumpCommand()
      : super(name: 'dump', description: 'Dump process_run aliases');

  @override
  FutureOr<bool> onRun() async {
    stdout.writeln(jsonPretty(ShellEnvironment().aliases));
    return true;
  }
}

/// Direct shell env Alias dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvAliasDumpCommand().parseAndRun(arguments);
}
