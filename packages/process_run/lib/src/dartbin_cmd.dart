import 'dart:convert';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/io/io.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

import 'common/import.dart';

/// dart bin file name
String dartBinFileName = 'dart${Platform.isWindows ? '.exe' : ''}';

/// Call dart executable
///
/// To prevent 'Observatory server failed to start after 1 tries' when
/// running from an idea use: includeParentEnvironment = false
class DartCmd extends _DartBinCmd {
  /// Call dart executable
  DartCmd(List<String> arguments) : super(dartBinFileName, arguments);
}

/// pub
class PubCmd extends DartCmd {
  /// Call pub executable
  PubCmd(List<String> arguments) : super(['pub', ...arguments]);
}

class _DartBinCmd extends ProcessCmd {
  final String binName;

  _DartBinCmd(this.binName, List<String> arguments)
    : super(join(dartSdkBinDirPath, binName), arguments);

  @override
  String toString() => executableArgumentsToString(binName, arguments);
}

/// pub run
class PubRunCmd extends PubCmd {
  final String _command;
  final List<String> _arguments;

  /// Call pub run
  PubRunCmd(this._command, this._arguments)
    : super(['run', _command, ..._arguments]);

  @override
  String toString() => executableArgumentsToString(_command, _arguments);
}

/// pub global run
class PubGlobalRunCmd extends PubCmd {
  final String _command;
  final List<String> _arguments;

  /// Call pub global run
  PubGlobalRunCmd(this._command, this._arguments)
    : super(['global', 'run', _command, ..._arguments]);

  @override
  String toString() => executableArgumentsToString(_command, _arguments);
}

/// Parse the text from Platform.version
Version parsePlatformVersion(String text) {
  return Version.parse(text.split(' ').first);
}

/// Parse the text from Platform.version
String parsePlatformChannel(String text) {
  //  // 2.8.0-dev.18.0.flutter-eea9717938 (be) (Wed Apr 1 08:55:31 2020 +0000) on "linux_x64"
  var parts = text.split(' ');
  if (parts.length > 1) {
    var channelText = parts[1];
    if (channelText.toLowerCase().contains('dev')) {
      return dartChannelDev;
    } else if (channelText.toLowerCase().contains('beta')) {
      return dartChannelBeta;
    }
  }
  return dartChannelStable;
}

/// Parse flutter version
Future<Version?> getDartBinVersion() async {
  // $ dart --version
  // Linux: Dart VM version: 2.7.0 (Unknown timestamp) on "linux_x64"

  var result = await runExecutableArguments('dart', [
    '--version',
  ], verbose: false);

  // Take from stderr first
  var version = parseDartBinVersionOutput(result.stderr.toString().trim());
  // Take stdout in case it changes
  version ??= parseDartBinVersionOutput(result.stdout.toString().trim());
  return version;
}

/// Parse version from 'dart --version' output.
Version? parseDartBinVersionOutput(String text) {
  var output = LineSplitter.split(text)
      .join(' ')
      .split(' ')
      .map((word) => word.trim())
      .where((word) => word.isNotEmpty);
  var foundDart = false;
  try {
    for (var word in output) {
      if (foundDart) {
        try {
          var version = Version.parse(word);
          return version;
        } catch (_) {}
      }
      if (word.toLowerCase().contains('dart')) {
        foundDart = true;
      }
    }
  } catch (_) {}
  return null;
}
