import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';

/// Convert a script to multiple commands
List<String> scriptToCommands(String script) {
  var commands = <String>[];
  // non null when previous line ended with ^ or \
  String currentCommand;
  for (var line in LineSplitter.split(script)) {
    line = line.trim();
    if (line.isNotEmpty) {
      if (line.startsWith('#')) {
        // Comment
      } else {
        // append to previous
        if (currentCommand != null) {
          line = currentCommand + line;
        }
        if (line.endsWith(' ^') || line.endsWith(r' \')) {
          // remove ending character
          currentCommand = line.substring(0, line.length - 1);
        } else {
          commands.add(line);
        }
      }
    }
  }
  return commands;
}

String _userAppDataPath;

/// Returns the user data path
String get userAppDataPath =>
    _userAppDataPath ??
    () {
      if (Platform.isWindows) {
        return Platform.environment['APPDATA'];
      }
      return null;
    }() ??
    join(userHomePath, '.config');

String _userHomePath;

/// Return the user home path
String get userHomePath => _userHomePath ??= Platform.environment['HOME'] ??
    Platform.environment['USERPROFILE'] ??
    () {}();

/// Expand home if needed
String expandPath(String path) {
  if (path == '~') {
    return userHomePath;
  }
  if (path.startsWith('~/') || path.startsWith(r'~\')) {
    return '${userHomePath}${path.substring(1)}';
  }
  return path;
}

/// Use to safely enclose an argument if needed
String shellArgument(String argument) => argumentToString(argument);
