import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:io/io.dart' as io;

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
Map<String, String> get environment => environmentFilterOutVmOptions(Platform.environment);

Map<String, String> environmentFilterOutVmOptions(Map<String, String> platformEnvironment) {
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
List<String> get windowsPathExts => _windowsPathExts ??= environmentGetWindowsPathExt(Platform.environment) ?? windowsDefaultPathExt;
const String windowsPathSeparator = ';';

List<String> environmentGetWindowsPathExt(Map<String, String> platformEnvironment) => environment['PATHEXT']?.split(windowsPathSeparator);

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
List<String> shellSplit(String command) => io.shellSplit(command.replaceAll(r'\', r'\\'));

/// Inverse of shell split
String shellJoin(List<String> parts) => parts.map((part) => shellArgument(part)).join(' ');