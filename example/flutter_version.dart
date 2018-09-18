import 'dart:async';

import 'package:process_run/cmd_run.dart';

Future main() async {
  if (flutterExecutablePath != null) {
    // await runCmd(ProcessCmd('flutter.bat', ['--version']), verbose: true);
    await runCmd(flutterCmd(['--version']), verbose: true);
  }
}
