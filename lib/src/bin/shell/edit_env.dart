import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/user_config.dart';
import 'package:process_run/which.dart';

/// pub run process_run:shell edit-env
Future editEnv(ArgParser parser, ArgResults results) async {
  final help = results == null ? false : results[flagHelp] as bool;

  void _printUsage() {
    stdout.writeln('Edit the environment file');
    stdout.writeln();
    stdout.writeln('Usage: pub run process_run:shell edit-env [<arguments>]');
    stdout.writeln();
    stdout.writeln('Options:');
    stdout.writeln(parser.usage);
    stdout.writeln();
  }

  if (help) {
    _printUsage();
    return;
  }

  final user = results[flagUser] as bool;
  final local = !user;

  var envFilePath = local ? getLocalEnvFilePath() : getUserEnvFilePath();

  if (verbose) {
    print('envFilePath: $envFilePath');
  }

  var label = local ? 'local' : 'user';
  final delete = results[flagDelete] as bool;
  if (delete) {
    stdout.writeln('Confirm that you want to delete file ($label) [Y]');
    stdout.writeln('  $envFilePath');
    final input = stdin.readLineSync();
    if (input.toLowerCase() == 'y') {
      try {
        await File(envFilePath).delete();
        stdout.writeln('Deleted');
      } catch (_) {}
    }
    return;
  }

  final displayInfo = results[flagInfo] as bool;
  if (displayInfo) {
    void displayInfo(String title, String path) {
      var config = loadFromPath(path);
      stdout.writeln('# $title');
      stdout.writeln(
          'file: ${relative(path, from: Directory.current?.path ?? '.')}');
      if (config.fileContent != null) {
        stdout.writeln('${config.fileContent}');
        stdout.writeln();
        if (config.yaml != null) {
          stdout.writeln('yaml: ${config.yaml}');
        }
        if (config.vars?.isNotEmpty ?? false) {
          stdout.writeln('vars: ${config.vars}');
        }
        if (config.paths?.isNotEmpty ?? false) {
          stdout.writeln('paths: ${config.paths}');
        }
      } else {
        stdout.writeln('not found');
      }
    }

    displayInfo('env ($label)', envFilePath);
    return;
  }

  var sampleFileContent = local
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
  Future _run(String command) async {
    await run(command, commandVerbose: verbose);
  }

  if (Platform.isLinux) {
    if (await which('gedit') != null) {
      await _run('gedit ${shellArgument(envFilePath)}');
      return;
    }
  } else if (Platform.isWindows) {
    if (await which('notepad') != null) {
      await _run('notepad ${shellArgument(envFilePath)}');
      return;
    }
  } else if (Platform.isMacOS) {
    if (await which('open') != null) {
      await _run('open -a TextEdit ${shellArgument(envFilePath)}');
      return;
    }
  }
  if (await which('vi') != null) {
    await _run('vi ${shellArgument(envFilePath)}');
    return;
  }
  print('no editor found');
}
