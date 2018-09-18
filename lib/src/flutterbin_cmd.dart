import 'dart:io';

import 'package:process_run/src/which.dart';

import '../process_run.dart';
import 'process_cmd.dart';

String __flutterExecutableName;
String get _flutterExecutableName =>
    __flutterExecutableName ??= Platform.isWindows ? 'flutter.bat' : 'flutter';

bool _flutterExecutablePathSearched = false;
String _flutterExecutablePath;
String get flutterExecutablePath {
  if (!_flutterExecutablePathSearched) {
    _flutterExecutablePath = whichSync('flutter');
    _flutterExecutablePathSearched = true;
  }
  return _flutterExecutablePath;
}

/// Dart command
ProcessCmd flutterCmd(List<String> arguments) {
  if (flutterExecutablePath != null) {
    return _FlutterCmd(arguments);
  }
  return null;
}

class _FlutterCmd extends ProcessCmd {
  _FlutterCmd(List<String> arguments)
      : super(_flutterExecutableName, arguments);

  @override
  String toString() => executableArgumentsToString('flutter', arguments);
}
