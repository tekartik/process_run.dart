import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart' as prefix0;
import 'package:process_run/shell_run.dart';
import 'package:process_run/src/bin/shell/env_edit.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/user_config.dart';

import 'env_var.dart';

class ShellEnvCommandBase extends ShellCommand {
  ShellEnvCommandBase({String name, String description})
      : super(name: name, description: description) {
    parser.addFlag(flagLocal,
        abbr: 'l', help: 'Use local env', negatable: false, defaultsTo: true);
    parser.addFlag(flagUser,
        abbr: 'u', help: 'Use user env instead of local env', negatable: false);
  }

  bool get local {
    final user = results[flagUser] as bool;
    final local = !user;
    return local;
  }

  String get envFilePath =>
      local ? getLocalEnvFilePath() : getUserEnvFilePath();

  List<String> _sampleFileContent;
  List<String> get sampleFileContent => _sampleFileContent ??= () {
        var content = local
            ? '''
# Local Environment path and variable for `Shell.run` calls.
#
# `path(s)` is a list of path, `var(s)` is a key/value map.
#
# Content example. See <https://github.com/tekartik/process_run.dart/blob/master/doc/user_config.md> for more information
#
# path:
#   - ./local
#   - bin/
# var:
#   MY_PWD: my_password
#   MY_USER: my user
# alias:
#   qr: /path/to/my_qr_app
  '''
            : '''
# Environment path and variable for `Shell.run` calls.
#
# `path` is a list of path, `var` is a key/value map.
#
# Content example. See <https://github.com/tekartik/process_run.dart/blob/master/doc/user_config.md> for more information
#
# path:
#   - ~/Android/Sdk/tools/bin
#   - ~/Android/Sdk/platform-tools
#   - ~/.gem/bin/
#   - ~/.pub-cache/bin
# var:
#   ANDROID_TOP: ~/.android
#   FLUTTER_BIN: ~/.flutter/bin
# alias:
#   qr: /path/to/my_qr_app

''';

        return LineSplitter.split(content).toList();
      }();
}

class ShellEnvCommand extends ShellEnvCommandBase {
  ShellEnvCommand()
      : super(
            name: 'env',
            description:
                'Manipulate local and global env vars, paths and aliases') {
    addCommand(ShellEnvVarCommand());
    addCommand(ShellEnvEditCommand());
  }
}

/// Direct shell env Alias dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvCommand().parseAndRun(arguments);
}

/// pub run process_run:shell edit-env
Future shellEnv(ArgParser parser, ArgResults results) async {
  final help = results == null ? false : results[flagHelp] as bool;

  void _printUsage() {
    stdout.writeln('Manipulate local and global env vars');
    stdout.writeln();
    stdout.writeln('Usage: ds env var <command>');
    stdout.writeln();
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

  /*
  final commandName = results.command.name;
  if (commandName == commandEnvVar) {
    await envVar(parser.commands[commandName], results.command);
  } else {
    exit(1);
  }
  if (verbose) {
    print('command: $command');
  }

   */
  await run(command);
}
