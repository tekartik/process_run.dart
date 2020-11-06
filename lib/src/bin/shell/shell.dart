import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:process_run/src/bin/shell/run.dart';
import 'package:process_run/src/common/import.dart';
import 'package:pub_semver/pub_semver.dart';

import 'env.dart';

Version shellBinVersion = Version(0, 1, 1);

const flagHelp = 'help';
const flagInfo = 'info';
const flagLocal = 'local';
const flagUser = 'user';
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

class MainShellCommand extends ShellCommand {
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
  //setupQuickLogging();

  final parser = mainCommand.parser;
  var editParser = parser.addCommand(commandEdit);
  //var runParser = parser.addCommand(commandRun);

  //envParser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);

  editParser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
  editParser.addFlag(flagDelete,
      abbr: 'd', help: 'Delete the env file', negatable: false);
  editParser.addFlag(flagInfo,
      abbr: 'i', help: 'display info', negatable: false);

  // runParser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
  // runParser.addFlag(flagInfo, abbr: 'i', help: 'display info', negatable: false);

  mainCommand.parseAndRun(arguments);
  //mainCommand.run();
  return;
  /*
  final help = results[flagHelp] as bool;
  verbose = results[flagVerbose] as bool;

  void _printUsage() {
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
    stdout.writeln();
  }

  if (help) {
    _printUsage();
    return;
  }

  // quick debug:
  /*
  verbose = devWarning(true);
  await editEnv(editParser, results.command);
  return;
   */

  if (results.command == null) {
    _printUsage();
    return;
  }

  final commandName = results.command.name;
  if (commandName == commandEdit) {
    await editEnv(editParser, results.command);
  } else if (commandName == commandRun) {
    await shellRun(runParser, results.command);
  } else {
    mainCommand.run();
  }*/
}

class ShellCommand {
  // Optional parent
  ShellCommand /*?*/ parent;
  String name;

  ArgParser get parser => _parser ??= ArgParser(allowTrailingOptions: false);
  FutureOr<bool> Function() _onRun;
  ArgParser _parser;
  ArgResults results;
  bool _verbose;

  // Set before run
  bool get verbose => _verbose ??= parent?.verbose;

  String _description;

  String get description => _description;
  Version _version;

  Version get version => _version ??= parent?.version;

  // name
  //   description
  void printNameDescription() {
    stdout.writeln('$name${parent != null ? '' : ' ${version.toString()}'}');
    if (description != null) {
      stdout.writeln('  $description');
    }
  }

  void printUsage() {
    printNameDescription();
    stdout.writeln();
    stdout.writeln(parser.usage);
    if (_commands.isNotEmpty) {
      stdout.writeln();
      printCommands();
    }
  }

  /// Prepend an em
  void printCommands() {
    _commands.forEach((name, value) {
      value.printNameDescription();
    });
    stdout.writeln();
  }

  void printBaseUsage() {
    printNameDescription();
    stdout.writeln();
    if (_commands.isNotEmpty) {
      stdout.writeln();
      printCommands();
    } else {
      stdout.writeln();
      stdout.writeln(parser.usage);
    }
  }

  ArgResults parse(List<String> arguments) {
    return results = parser.parse(arguments);
  }

  @nonVirtual
  FutureOr<bool> parseAndRun(List<String> arguments) {
    parse(arguments);
    return run();
  }

  final _commands = <String, ShellCommand>{};

  ShellCommand(
      {@required this.name,
      Version version,
      ArgParser parser,
      ShellCommand parent,
      @deprecated FutureOr<bool> Function() onRun,
      String description}) {
    _onRun = onRun;
    _parser = parser;
    _description = description;
    _version = version;
    // read or create
    parser = this.parser;
    parser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
    if (parent == null) {
      parser.addFlag(flagVersion,
          help: 'Print the command version', negatable: false);

      parser.addFlag(flagVerbose, help: 'Verbose mode', negatable: false);
    }
  }

  void addCommand(ShellCommand command) {
    parser.addCommand(command.name, command.parser);
    _commands[command.name] = command;
    command.parent = this;
  }

  /// To override
  ///
  /// return true if handled.
  @visibleForOverriding
  FutureOr<bool> onRun() {
    if (_onRun != null) {
      return _onRun();
    }
    return false;
  }

  /// Get a flag
  bool getFlag(String name) => results[name] as bool;

  @nonVirtual
  FutureOr<bool> run() async {
    // Handle verbose
    // Handle version first
    if (parent == null) {
      final hasVersion = getFlag(flagVersion);
      if (hasVersion) {
        stdout.writeln(version);
        return true;
      }
    }
    // Handle help
    final help = results[flagHelp] as bool;

    if (help) {
      printUsage();
      return true;
    }

    // Find the command if any
    var command = results.command;
    if (command != null) {
      var shellCommand = _commands[command.name];
      if (shellCommand != null) {
        // Set the result in the the shell command
        shellCommand.results = command;
        return shellCommand.run();
      }
    }
    var ran = await onRun();
    if (!ran) {
      stderr.writeln('No command ran');
      printBaseUsage();
    }
    return false;
  }

  @override
  String toString() => 'ShellCommand($name)';
}
