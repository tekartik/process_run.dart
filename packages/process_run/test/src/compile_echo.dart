import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

/// Return the executable path.
Future<String> compileEchoExample({bool force = false}) async {
  var folder =
      Platform.isWindows ? 'windows' : (Platform.isMacOS ? 'macos' : 'linux');
  var exeExtension = Platform.isWindows ? '.exe' : '';
  var echoExePath = join('build', folder, 'process_run_echo$exeExtension');
  var echoExeDir = dirname(echoExePath);
  var shell = Shell(verbose: false);
  if (!File(echoExePath).existsSync() || force) {
    Directory(echoExeDir).createSync(recursive: true);
    await shell.run(
        'dart compile exe ${shellArgument(join('example', 'echo.dart'))} -o ${shellArgument(echoExePath)}');
  }
  return echoExePath;
}
