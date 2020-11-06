import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:process_run/src/common/import.dart';

import 'env.dart';

class ShellEnvEditCommand extends ShellEnvCommandBase {
  ShellEnvEditCommand()
      : super(name: 'Edit', description: 'Edit the environment file');

  @override
  void printUsage() {
    // TODO: implement printUsage
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    if (verbose) {
      print('envFilePath: $envFilePath');
    }

    /*
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
      return true;
    }*/

    /*
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
      return true;
    }
     */

    var envFile = File(envFilePath);
    if (!envFile.existsSync()) {
      await Directory(dirname(envFilePath)).create(recursive: true);
      //await envFile.writeAsString(sampleFileContent, flush: true);
    }
    Future _run(String command) async {
      await run(command, commandVerbose: verbose);
    }

    if (Platform.isLinux) {
      if (await which('gedit') != null) {
        await _run('gedit ${shellArgument(envFilePath)}');
        return true;
      }
    } else if (Platform.isWindows) {
      if (await which('notepad') != null) {
        await _run('notepad ${shellArgument(envFilePath)}');
        return true;
      }
    } else if (Platform.isMacOS) {
      if (await which('open') != null) {
        await _run('open -a TextEdit ${shellArgument(envFilePath)}');
        return true;
      }
    }
    if (await which('vi') != null) {
      await _run('vi ${shellArgument(envFilePath)}');
      return true;
    }
    print('no editor found');
    return false;
  }
}

/// Direct shell env Edit dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvEditCommand().parseAndRun(arguments);
}
