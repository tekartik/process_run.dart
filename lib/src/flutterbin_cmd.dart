import 'dart:io';

import 'package:process_run/src/which.dart';

import '../process_run.dart';
import 'process_cmd.dart';

String __flutterExecutableName;
String get _flutterExecutableName =>
    __flutterExecutableName ??= Platform.isWindows ? 'flutter.bat' : 'flutter';

bool _flutterExecutablePathSearched = false;
String _flutterExecutablePath;
@deprecated
String get flutterExecutablePath {
  if (!_flutterExecutablePathSearched) {
    _flutterExecutablePath = whichSync('flutter');
    _flutterExecutablePathSearched = true;
  }
  return _flutterExecutablePath;
}

/// Dart command
@deprecated
ProcessCmd flutterCmd(List<String> arguments) {
  if (_flutterExecutableName != null) {
    return FlutterCmd(arguments);
  }
  return null;
}

// Somehow flutter requires runInShell on Linux
class FlutterCmd extends ProcessCmd {
  FlutterCmd(List<String> arguments)
      : super(_flutterExecutableName, arguments, runInShell: true);

  @override
  String toString() => executableArgumentsToString('flutter', arguments);
}
