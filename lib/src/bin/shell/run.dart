import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart' as prefix0;
import 'package:process_run/shell_run.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/user_config.dart';

/// pub run process_run:shell edit-env
Future shellRun(ArgParser parser, ArgResults results) async {
  final help = results == null ? false : results[flagHelp] as bool;

  void _printUsage() {
    stdout.writeln('Run a command');
    stdout.writeln();
    stdout.writeln('Usage: pub run process_run:shell run <command>');
    stdout.writeln(
        '  command being a command line as a single argument, examples:');
    stdout.writeln("  - 'firebase deploy'");
    stdout.writeln('  - script.bat');
    stdout.writeln('  - script.sh');
    stdout.writeln('');
    stdout.writeln('Get information about the added path(s) and var(s)');
    stdout.writeln('  pub run process_run:shell run --version');

    stdout.writeln('Options:');
    stdout.writeln(parser.usage);
    stdout.writeln();
  }

  if (help) {
    _printUsage();
    return;
  }

  String command;
  var commands = results.rest;
  if (commands.isEmpty) {
    stderr.writeln('missing command');
  } else if (commands.length == 1) {
    command = commands.first;
  } else {
    command = prefix0.argumentsToString(commands);
  }

  final displayInfo = results[flagInfo] as bool;
  if (displayInfo) {
    void displayInfo(String title, String path) {
      var config = loadFromPath(path);
      stdout.writeln('# $title');
      stdout.writeln(
          'file: ${relative(path, from: Directory.current?.path ?? '.')}');
      stdout.writeln('vars: ${config.vars}');
      stdout.writeln('paths: ${config.paths}');
    }

    stdout.writeln('command: $command');
    displayInfo('user_env', getUserEnvFilePath());
    displayInfo('local_env', getLocalEnvFilePath());

    return;
  }

  if (command == null) {
    exit(1);
  }
  if (verbose) {
    print('command: $command');
  }
  await run(command);
}
