import 'dart:async';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/run.dart';
import 'package:process_run/src/common/import.dart';
import 'package:pub_semver/pub_semver.dart';

import 'env.dart';
import 'import.dart';

Version shellBinVersion = Version(0, 1, 1);

const flagHelp = 'help';
const flagInfo = 'info';
const flagLocal = 'local';
const flagUser = 'user';
// Force an action
const flagForce = 'force';
const flagDelete = 'delete';
const flagVerbose = 'verbose';
const flagVersion = 'version';

const commandEdit = 'edit-env';
const commandRun = 'run';
const commandEnv = 'env';

const commandEnvEdit = 'edit';
const commandEnvVar = 'var';
const commandEnvVarDump = 'dump';
const commandEnvPath = 'path';
const commandEnvAliases = 'alias';

String get script => 'ds';

bool verbose = false;

class MainShellCommand extends ShellBinCommand {
  MainShellCommand() : super(name: 'ds', version: shellBinVersion) {
    addCommand(ShellEnvCommand());
    addCommand(ShellRunCommand());
  }

  @override
  void printUsage() {
    stdout.writeln('*** ubuntu/windows only for now ***');
    stdout.writeln('Process run shell configuration utility');
    stdout.writeln();
    stdout.writeln('Usage: $script <command> [<arguments>]');
    stdout.writeln('Usage: pub run process_run:shell <command> [<arguments>]');
    stdout.writeln();
    stdout.writeln('Example: pub run process_run:shell edit-env');
    stdout.writeln('will open the env file using gedit');
    stdout.writeln();
    stdout.writeln('Global options:');
    stdout.writeln(parser.usage);
    stdout.writeln();
    stdout.writeln('Available commands:');
    stdout.writeln('  edit-env    Edit environment file');
    stdout.writeln(
        '  run         Run a command with user and local env path and vars');
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() {
    return false;
  }
}

final mainCommand = MainShellCommand();

///
/// write rest arguments as lines
///
Future main(List<String> arguments) async {
  await mainCommand.parseAndRun(arguments);
  await promptTerminate();
}
