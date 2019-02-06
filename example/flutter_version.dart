import 'dart:async';

import 'package:process_run/cmd_run.dart';

Future main() async {
  if (isFlutterSupportedSync) {
    // await runCmd(ProcessCmd('flutter.bat', ['--version']), verbose: true);
    await runCmd(FlutterCmd(['--version']), verbose: true);
  } else {
    print('Flutter not in path or not installed');
  }
}
