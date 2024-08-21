import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

/// Return the executable path.
Future<String> compileShellBin({bool force = false}) async {
  var folder =
      Platform.isWindows ? 'windows' : (Platform.isMacOS ? 'macos' : 'linux');
  var exeExtension = Platform.isWindows ? '.exe' : '';
  var dsExePath = join('build', folder, 'ds$exeExtension');
  var dsExeDir = dirname(dsExePath);
  var shell = Shell(verbose: false);
  if (!File(dsExePath).existsSync() || force) {
    Directory(dsExeDir).createSync(recursive: true);
    await shell.run(
        'dart compile exe ${shellArgument(join('bin', 'shell.dart'))} -o ${shellArgument(dsExePath)}');
  }
  return dsExePath;
}
