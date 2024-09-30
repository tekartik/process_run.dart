import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:pub_semver/pub_semver.dart';

/// Return the executable path.
Future<String> compileShellBin({bool force = false}) async {
  var folder =
      Platform.isWindows ? 'windows' : (Platform.isMacOS ? 'macos' : 'linux');
  var exeExtension = Platform.isWindows ? '.exe' : '';
  var dsExePath = join('build', folder, 'ds$exeExtension');
  var dsExeDir = dirname(dsExePath);
  var shell = Shell(verbose: false);
  if (File(dsExePath).existsSync()) {
    try {
      var output = (await shell.run('$dsExePath --version')).outText.trim();
      if (Version.parse(output) != shellBinVersion) {
        force = true;
      }
    } catch (_) {
      // ignore
      force = true;
    }
  }

  if (!File(dsExePath).existsSync() || force) {
    Directory(dsExeDir).createSync(recursive: true);
    await shell.run(
        'dart compile exe ${shellArgument(join('bin', 'shell.dart'))} -o ${shellArgument(dsExePath)}');
  }
  return dsExePath;
}
