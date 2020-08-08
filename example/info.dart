import 'dart:async';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/which.dart';

Future main() async {
  print('dartExecutable: $dartExecutable');
  print('flutterExecutablePath: $flutterExecutablePath');
  print('which(\'dart\'): ${await which('dart')}');
  print('which(\'flutter\'): ${await which('flutter')}');
  print('which(\'pub\'): ${await which('pub')}');
}
