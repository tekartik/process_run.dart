import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/run.dart';
import 'package:process_run/src/version.dart';

import 'env.dart';
import 'import.dart';

/// The shell bin version
final shellBinVersion = packageVersion;

/// Help flag
const flagHelp = 'help';

/// Info flag
const flagInfo = 'info';

/// Local flag
const flagLocal = 'local';

/// User flag
const flagUser = 'user';

/// Force an action
const flagForce = 'force';

/// Delete flag
const flagDelete = 'delete';

/// Verbose flag
const flagVerbose = 'verbose';

/// Version flag
const flagVersion = 'version';

/// Command edit-env
const commandEdit = 'edit-env';

/// Command run
const commandRun = 'run';

/// Command env
const commandEnv = 'env';

/// Command env edit
const commandEnvEdit = 'edit';

/// Command env var
const commandEnvVar = 'var';

/// Command env var dump
const commandEnvVarDump = 'dump';

/// Command env path
const commandEnvPath = 'path';

/// Command env aliases
const commandEnvAliases = 'alias';

/// Script shortcut
String get script => 'ds';

/// Main shell command
class MainShellCommand extends ShellBinCommand {
  /// Main shell command
  MainShellCommand() : super(name: script, version: shellBinVersion) {
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
    stdout.writeln('Examples:');
    stdout.writeln();
    stdout.writeln('''
# Set a local env variable
ds env var set MY_VAR my_value
# Get a local env variable
ds env var get USER
# Prepend a path
ds env path prepend ~/.my_path
# Add an alias
ds env alias set hello_world echo Hello World
# Run a command in the overriden envionement
ds run hello_world
ds run echo MY_VAR
# Edit the local environment file
ds env edit
''');
    super.printUsage();
  }

  @override
  void printBaseUsage() {
    stdout.writeln('Process run shell configuration utility');
    stdout.writeln(' -h, --help       Usage help');
    // super.printBaseUsage();
  }

  @override
  FutureOr<bool> onRun() {
    return false;
  }
}

/// Main shell command
final mainCommand = MainShellCommand();

///
/// write rest arguments as lines
///
Future main(List<String> arguments) async {
  await mainCommand.parseAndRun(arguments);
  await promptTerminate();
}
