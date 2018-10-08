import 'dart:async';

import 'package:process_run/cmd_run.dart';

Future main() async {
  if (isFlutterSupported) {
    // await runCmd(ProcessCmd('flutter.bat', ['--version']), verbose: true);
    await runCmd(FlutterCmd(['--version']), verbose: true);
  }
}
