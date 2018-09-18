import 'package:process_run/src/which.dart';

import '../process_run.dart';
import 'process_cmd.dart';

bool _flutterExecutablePathSearched = false;
String _flutterExecutablePath;
String get flutterExecutablePath {
  if (!_flutterExecutablePathSearched) {
    _flutterExecutablePath = which('flutter');
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
  _FlutterCmd(List<String> arguments) : super(flutterExecutablePath, arguments);

  @override
  String toString() => executableArgumentsToString('flutter', arguments);
}
