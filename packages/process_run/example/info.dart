import 'dart:async';

import 'package:process_run/cmd_run.dart' show flutterExecutablePath;
import 'package:process_run/shell.dart';
import 'package:process_run/stdio.dart';

Future main() async {
  stdout.writeln('dartExecutable: $dartExecutable');
  stdout.writeln('flutterExecutablePath: $flutterExecutablePath');
  stdout.writeln('which(\'dart\'): ${await which('dart')}');
  stdout.writeln('which(\'flutter\'): ${await which('flutter')}');
  await run('dart --version');
}
