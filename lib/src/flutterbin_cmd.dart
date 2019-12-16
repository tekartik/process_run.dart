import 'dart:convert';

import 'package:process_run/process_run.dart' hide run;
import 'package:process_run/shell_run.dart';
import 'package:process_run/src/which.dart';
import 'package:pub_semver/pub_semver.dart';

import 'process_cmd.dart';

String _flutterExecutablePath;

/// Resolved flutter path if found
String get flutterExecutablePath =>
    _flutterExecutablePath ??= whichSync('flutter');

/// Test only
@deprecated
set flutterExecutablePath(String path) => _flutterExecutablePath = '';
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

// to deprecate
Future<Version> getFlutterVersion() => getFlutterBinVersion();

/// Get flutter version.
///
/// Returns null if flutter cannot be found in the path
Future<Version> getFlutterBinVersion() async {
  // $ flutter --version
  // Flutter 1.7.8+hotfix.4 • channel stable • https://github.com/flutter/flutter.git
  // Framework • revision 20e59316b8 (8 weeks ago) • 2019-07-18 20:04:33 -0700
  // Engine • revision fee001c93f
  // Tools • Dart 2.4.0
  try {
    var results = await run('flutter --version');
    // Take from stderr first
    var resultOutput = results.first.stderr.toString().trim();
    if (resultOutput.isEmpty) {
      resultOutput = results.first.stdout.toString().trim();
    }
    var output = LineSplitter.split(resultOutput)
        .join(' ')
        .split(' ')
        .map((word) => word?.trim())
        .where((word) => word?.isNotEmpty ?? false);
    // Take the first version string after flutter
    var foundFlutter = false;

    for (var word in output) {
      if (foundFlutter) {
        try {
          var version = Version.parse(word);
          if (version != null) {
            return version;
          }
        } catch (_) {}
      }
      if (word.toLowerCase().contains('flutter')) {
        foundFlutter = true;
      }
    }
  } catch (_) {}
  return null;
}
