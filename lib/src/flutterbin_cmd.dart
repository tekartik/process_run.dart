import 'dart:convert';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/process_run.dart';
import 'package:process_run/src/which.dart';
import 'package:pub_semver/pub_semver.dart';

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

/// Parse flutter version
Future<Version> getFlutterVersion() async {
  // $ flutter --version
  // Flutter 1.7.8+hotfix.4 • channel stable • https://github.com/flutter/flutter.git
  // Framework • revision 20e59316b8 (8 weeks ago) • 2019-07-18 20:04:33 -0700
  // Engine • revision fee001c93f
  // Tools • Dart 2.4.0
  var cmd = FlutterCmd(['--version']);
  var output = LineSplitter.split((await runCmd(cmd)).stdout.toString())
      .join(' ')
      .split(' ')
      .map((word) => word?.trim())
      .where((word) => word?.isNotEmpty ?? false);
  var foundFlutter = false;
  try {
    for (var word in output) {
      if (foundFlutter) {
        return Version.parse(word);
      }
      if (word.toLowerCase().contains('flutter')) {
        foundFlutter = true;
      }
    }
  } catch (_) {}
  return null;
}
