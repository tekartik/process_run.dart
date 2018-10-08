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

@deprecated
ProcessCmd flutterCmd(List<String> arguments) {
  if (_flutterExecutableName != null) {
    return FlutterCmd(arguments);
  }
  return null;
}

bool _isFlutterSupported;
bool get isFlutterSupported =>
    _isFlutterSupported ??= whichSync('flutter') != null;

///
/// build a flutter command
class FlutterCmd extends ProcessCmd {
  // Somehow flutter requires runInShell on Linux, does not hurt on windows
  FlutterCmd(List<String> arguments)
      : super(_flutterExecutableName, arguments, runInShell: true);

  @override
  String toString() => executableArgumentsToString('flutter', arguments);
}
