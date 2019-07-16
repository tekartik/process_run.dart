#!/usr/bin/env dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/user_config.dart';
import 'package:process_run/which.dart';
import 'package:pub_semver/pub_semver.dart';

Version version = Version(0, 1, 1);

const flagHelp = 'help';
const flagVerbose = 'verbose';
const flagVersion = 'version';
const commandEdit = 'edit-env';

bool verbose;

///
/// write rest arguments as lines
///
Future main(List<String> arguments) async {
  //setupQuickLogging();

  ArgParser parser = ArgParser(allowTrailingOptions: false);
  var editParser = parser.addCommand(commandEdit);
  parser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag(flagVerbose, abbr: 'v', help: 'Verbose', negatable: false);

  editParser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);

  parser.addFlag(flagVersion,
      help: 'Print the command version', negatable: false);

  final results = parser.parse(arguments);

  bool help = results[flagHelp] as bool;
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
    stdout.writeln("Global options:");
    stdout.writeln(parser.usage);
    stdout.writeln();
    stdout.writeln("Available commands:");
    stdout.writeln("  edit-env    Edit environment file");
    stdout.writeln();
  }

  if (help) {
    _printUsage();
    return;
  }

  bool displayVersion = results[flagVersion] as bool;

  if (displayVersion) {
    stdout.write('process_run:shell version ${version}');
    stdout.writeln('VM: ${Platform.resolvedExecutable} ${Platform.version}');
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

  if (results.command.name == commandEdit) {
    await editEnv(editParser, results.command);
  }
}

/// pub run process_run:shell edit-env
Future editEnv(ArgParser parser, ArgResults results) async {
  bool help = results == null ? false : results[flagHelp] as bool;

  void _printUsage() {
    stdout.writeln('Edit the environment file');
    stdout.writeln();
    stdout.writeln('Usage: pub run process_run:shell edit-env [<arguments>]');
    stdout.writeln();
    stdout.writeln("Options:");
    stdout.writeln(parser.usage);
    stdout.writeln();
  }

  if (help) {
    _printUsage();
    return;
  }

  var envFilePath = getUserEnvFilePath(shellEnvironment);

  if (verbose) {
    print('envFilePath: $envFilePath');
  }
  var sampleFileContent = '''
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

''';
  var envFile = File(envFilePath);
  if (!envFile.existsSync()) {
    if (Platform.isWindows) {
      sampleFileContent =
          const LineSplitter().convert(sampleFileContent).join('\r\n');
    }
    await Directory(dirname(envFilePath)).create(recursive: true);
    await envFile.writeAsString(sampleFileContent, flush: true);
  }
  if (Platform.isLinux) {
    if (await which('gedit') != null) {
      await run('gedit ${shellArgument(envFilePath)}');
      return;
    }
  } else if (Platform.isWindows) {
    if (await which('notepad') != null) {
      await run('notepad ${shellArgument(envFilePath)}');
      return;
    }
  } else if (Platform.isMacOS) {
    if (await which('open') != null) {
      await run('open -a TextEdit ${shellArgument(envFilePath)}');
      return;
    }
  }
  if (await which('vi') != null) {
    await run('vi ${shellArgument(envFilePath)}');
    return;
  }
  print('no editor found');
}
