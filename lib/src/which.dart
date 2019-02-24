import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/src/shell_utils.dart';

Future<String> which(String command, {Map<String, String> env}) async {
  return whichSync(command, env: env);
}

/// Find the command according to the [paths] or env variables (`PATH`)
String whichSync(String command,
    {Map<String, String> env, List<String> paths}) {
  // only valid for relative command
  if (isAbsolute(command)) {
    return command;
  }
  env ??= Platform.environment;
  var isWindows = Platform.isWindows;

  var pathSeparator = isWindows ? ';' : ':';

  paths ??= <String>[];

  var envPaths = env['PATH']?.split(pathSeparator);
  if (envPaths != null) {
    paths.addAll(envPaths);
  }

  if (paths != null) {
    // Add current directory
    paths.add(Directory.current.path);
    for (var path in paths) {
      var commandPath = absolute(normalize(join(path, command)));

      if (isWindows) {
        for (var ext in windowsPathExts) {
          var commandPathWithExt = '$commandPath$ext';
          if (File(commandPathWithExt).existsSync()) {
            return commandPathWithExt;
          }
        }
        // Try without extension
        if (File(commandPath).existsSync()) {
          return commandPath;
        }
      } else {
        var stats = File(commandPath).statSync();
        if (stats.type != FileSystemEntityType.notFound) {
          // Check executable permission
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
