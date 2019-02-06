import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';

Future<String> which(String command, {Map<String, String> env}) async {
  return whichSync(command, env: env);
}

String whichSync(String command, {Map<String, String> env}) {
  // only valid for relative command
  if (isAbsolute(command)) {
    return command;
  }
  env ??= Platform.environment;
  var isWindows = Platform.isWindows;

  var pathSeparator = isWindows ? ';' : ':';

  var paths = env['PATH']?.split(pathSeparator);

  List<String> winExeExtensions;
  if (isWindows) {
    winExeExtensions =
        (env['PATHEXT'] ?? '.exe;.bat;.cmd;.com')?.split(pathSeparator);
  }

  if (paths != null) {
    // Add current directory
    paths.add(Directory.current.path);
    for (var path in paths) {
      var commandPath = absolute(normalize(join(path, command)));

      if (isWindows) {
        if (winExeExtensions != null) {
          for (var ext in winExeExtensions) {
            var commandPathWithExt = '$commandPath$ext';
            if (File(commandPathWithExt).existsSync()) {
              return commandPathWithExt;
            }
          }
        }
        // Try without extension
        if (File(commandPath).existsSync()) {
          return commandPath;
        }
      } else {
        var stats = File(commandPath).statSync();
        if (stats.type != FileSystemEntityType.notFound) {
          if (stats.mode & 0x49 != 0) {
            // binary 001001001
            // executable
            return commandPath;
          }
        }
      }
    }
  }
  return null;
}
