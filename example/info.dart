import 'dart:async';

import 'package:process_run/cmd_run.dart' show flutterExecutablePath;
import 'package:process_run/shell.dart';

Future main() async {
  print('dartExecutable: $dartExecutable');
  print('flutterExecutablePath: $flutterExecutablePath');
  print('which(\'dart\'): ${await which('dart')}');
  print('which(\'flutter\'): ${await which('flutter')}');
  print('which(\'pub\'): ${await which('pub')}');
  await run('dart --version');
}
