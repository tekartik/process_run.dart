import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:process_run/src/bin/shell/edit_env.dart';
import 'package:process_run/src/bin/shell/run.dart';
import 'package:process_run/src/common/import.dart';
import 'package:pub_semver/pub_semver.dart';

Version version = Version(0, 1, 1);

const flagHelp = 'help';
const flagInfo = 'info';
const flagLocal = 'local';
const flagUser = 'user';
const flagDelete = 'delete';
const flagVerbose = 'verbose';
const flagVersion = 'version';

const commandEdit = 'edit-env';
const commandRun = 'run';

bool verbose = false;

///
/// write rest arguments as lines
///
Future main(List<String> arguments) async {
  //setupQuickLogging();

  final parser = ArgParser(allowTrailingOptions: false);
  var editParser = parser.addCommand(commandEdit);
  var runParser = parser.addCommand(commandRun);
  parser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag(flagVerbose, abbr: 'v', help: 'Verbose', negatable: false);

  editParser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
  editParser.addFlag(flagLocal,
      abbr: 'l',
      help: 'Edit/Delete/Display local env',
      negatable: false,
      defaultsTo: true);
  editParser.addFlag(flagUser,
      abbr: 'u',
      help: 'Edit/Delete/Display user env instead of local env',
      negatable: false);
  editParser.addFlag(flagDelete,
      abbr: 'd', help: 'Delete the env file', negatable: false);
  editParser.addFlag(flagInfo,
      abbr: 'i', help: 'display info', negatable: false);

  runParser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
  runParser.addFlag(flagInfo,
      abbr: 'i', help: 'display info', negatable: false);

  parser.addFlag(flagVersion,
      help: 'Print the command version', negatable: false);

  final results = parser.parse(arguments);

  final help = results[flagHelp] as bool;
  verbose = results[flagVerbose] as bool;

  void _printUsage() {
    stdout.writeln('*** ubuntu/windows only for now ***');
    stdout.writeln('Process run shell configuration utility');
    stdout.writeln();
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

  final displayVersion = results[flagVersion] as bool;

  if (displayVersion) {
    stdout.writeln('version: ${version}');
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
  }
}
