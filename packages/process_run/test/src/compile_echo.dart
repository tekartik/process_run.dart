import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/version.dart';
import 'package:pub_semver/pub_semver.dart';

var _echoVersionOk = false;

/// Return the executable path.
Future<String> compileEchoExample({bool force = false}) async {
  var folder =
      Platform.isWindows ? 'windows' : (Platform.isMacOS ? 'macos' : 'linux');
  var exeExtension = Platform.isWindows ? '.exe' : '';
  var echoExePath = join('build', folder, 'process_run_echo$exeExtension');
  var echoExeDir = dirname(echoExePath);
  var shell = Shell(verbose: false);
  var file = File(echoExePath);
  var needCompile = force || !file.existsSync();

  if (!needCompile && _echoVersionOk) {
    return echoExePath;
  }
  if (!needCompile && file.existsSync()) {
    try {
      var version = Version.parse(
          (await shell.run('$echoExePath --version')).outText.trim());
      if (version != packageVersion) {
        needCompile = true;
      } else {
        _echoVersionOk = true;
        return echoExePath;
      }
    } catch (_) {
      needCompile = true;
    }
  }
  if (needCompile) {
    Directory(echoExeDir).createSync(recursive: true);
    await shell.run(
        'dart compile exe ${shellArgument(join('example', 'echo.dart'))} -o ${shellArgument(echoExePath)}');
  }
  return echoExePath;
}
