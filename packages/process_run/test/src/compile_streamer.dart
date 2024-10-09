import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/version.dart';
import 'package:pub_semver/pub_semver.dart';

var _streamerVersionOk = false;

/// Return the executable path.
Future<String> compileStreamerExample({bool force = false}) async {
  var folder =
      Platform.isWindows ? 'windows' : (Platform.isMacOS ? 'macos' : 'linux');
  var exeExtension = Platform.isWindows ? '.exe' : '';
  var exe = join('build', folder, 'process_run_streamer$exeExtension');
  var exeDir = dirname(exe);

  var shell = Shell(verbose: false);
  var file = File(exe);

  var needCompile = force || !file.existsSync();
  if (!needCompile && _streamerVersionOk) {
    return exe;
  }
  if (!needCompile && file.existsSync()) {
    try {
      var version =
          Version.parse((await shell.run('$exe --version')).outText.trim());
      if (version != packageVersion) {
        needCompile = true;
      } else {
        _streamerVersionOk = true;
        return exe;
      }
    } catch (_) {
      needCompile = true;
    }
  }
  if (needCompile) {
    Directory(exeDir).createSync(recursive: true);
    await shell.run(
        'dart compile exe ${shellArgument(join('example', 'streamer.dart'))} -o ${shellArgument(exe)}');
  }
  return exe;
}
