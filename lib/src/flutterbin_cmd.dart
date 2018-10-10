import 'package:process_run/src/utils.dart';
import 'package:process_run/src/which.dart';
import '../process_run.dart';
import 'process_cmd.dart';

String get _flutterExecutableName => getShellCmdBinFileName('flutter');

@deprecated
String get flutterExecutablePath => whichSync('flutter');

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
