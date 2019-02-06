import 'package:process_run/src/which.dart';
import 'package:process_run/process_run.dart';
import 'process_cmd.dart';

String _flutterExecutablePath;

/// Resolved flutter path if found
String get flutterExecutablePath =>
    _flutterExecutablePath ??= whichSync('flutter');

@deprecated
ProcessCmd flutterCmd(List<String> arguments) => FlutterCmd(arguments);

bool get isFlutterSupported => isFlutterSupportedSync;

/// true if flutter is supported
bool get isFlutterSupportedSync => flutterExecutablePath != null;

/// build a flutter command
class FlutterCmd extends ProcessCmd {
  // Somehow flutter requires runInShell on Linux, does not hurt on windows
  FlutterCmd(List<String> arguments)
      : super(flutterExecutablePath, arguments, runInShell: true);

  @override
  String toString() => executableArgumentsToString('flutter', arguments);
}
