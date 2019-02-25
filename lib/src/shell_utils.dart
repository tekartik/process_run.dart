import 'dart:convert';
import 'dart:io';

import 'package:io/io.dart' as io;
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/common/import.dart';

/// Convert a script to multiple commands
List<String> scriptToCommands(String script) {
  var commands = <String>[];
  // non null when previous line ended with ^ or \
  String currentCommand;
  for (var line in LineSplitter.split(script)) {
    line = line.trim();
    if (line.isNotEmpty) {
      if (line.startsWith('#')) {
        commands.add(line);
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
///
/// On windows, it is read from the `APPDATA` environment variable. Otherwise
/// it is the `~/.config` folder
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

/// Return the user home path.
///
/// Usually read from the `HOME` environment variable or `USERPROFILE` on
/// Windows.
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

/// Environment without debug VM_OPTIONS
///
/// Instead replace with an optional TEKARTIK_DART_VM_OPTIONS
Map<String, String> get shellEnvironment =>
    environmentFilterOutVmOptions(Platform.environment);

Map<String, String> environmentFilterOutVmOptions(
    Map<String, String> platformEnvironment) {
  Map<String, String> environment;
  var vmOptions = platformEnvironment['DART_VM_OPTIONS'];
  if (vmOptions != null) {
    environment = Map<String, String>.from(platformEnvironment);
    environment.remove('DART_VM_OPTIONS');
  }
  var tekartikVmOptions = platformEnvironment['TEKARTIK_DART_VM_OPTIONS'];
  if (tekartikVmOptions != null) {
    environment ??= Map<String, String>.from(platformEnvironment);
    environment['DART_VM_OPTIONS'] = tekartikVmOptions;
  }
  return environment ?? platformEnvironment;
}

const windowsDefaultPathExt = <String>['.exe', '.bat', '.cmd', '.com'];
List<String> _windowsPathExts;

/// Default extension for PATHEXT on Windows
List<String> get windowsPathExts => _windowsPathExts ??=
    environmentGetWindowsPathExt(Platform.environment) ?? windowsDefaultPathExt;
const String windowsPathSeparator = ';';

List<String> environmentGetWindowsPathExt(
        Map<String, String> platformEnvironment) =>
    shellEnvironment['PATHEXT']
        ?.split(windowsPathSeparator)
        ?.map((ext) => ext.toLowerCase())
        ?.toList(growable: false);

/// fix runInShell for Windows
bool fixRunInShell(bool runInShell, String executable) {
  if (Platform.isWindows) {
    if (runInShell != false) {
      if (runInShell == null) {
        if (extension(executable).toLowerCase() != '.exe') {
          return true;
        }
      }
    }
  }
  return runInShell ?? false;
}

/// Use io package shellSplit implementation
List<String> shellSplit(String command) =>
    io.shellSplit(command.replaceAll(r'\', r'\\'));

/// Inverse of shell split
String shellJoin(List<String> parts) =>
    parts.map((part) => shellArgument(part)).join(' ');

/// Find command in path
String findExecutableSync(String command, List<String> paths) {
  for (var path in paths) {
    var commandPath = absolute(normalize(join(path, command)));

    if (Platform.isWindows) {
      for (var ext in windowsPathExts) {
        var commandPathWithExt = '$commandPath$ext';
        if (File(commandPathWithExt).existsSync()) {
          return normalize(commandPathWithExt);
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
  return null;
}

List<String> _platformEnvironmentPaths;

/// Get platform environment path
List<String> get platformEnvironmentPaths =>
    _platformEnvironmentPaths ??= _getEnvironmentPaths(Platform.environment);

List<String> getEnvironmentPaths([Map<String, String> environment]) {
  if (environment == null) {
    return platformEnvironmentPaths;
  }
  return _getEnvironmentPaths(environment);
}

/// No io dependency here.
///
/// Never null
List<String> _getEnvironmentPaths(Map<String, String> environment) =>
    (environment ?? <String, String>{})['PATH']
        ?.split(Platform.isWindows ? ';' : ':') ??
    <String>[];

/// Write a string line to the ouput
void streamSinkWriteln(StreamSink<List<int>> sink, String message) =>
    streamSinkWrite(sink, "${message}\n");

/// Write a string to a to sink
void streamSinkWrite(StreamSink<List<int>> sink, String message) =>
    sink.add(message.codeUnits);
