import 'dart:async';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/stdio.dart';

Future main() async {
  stdout.writeln('dart: ${await which('dart')}');
  var dartBinVersion = await getDartBinVersion();
  stdout.writeln('dartBinVersion: $dartBinVersion');
  await Shell().run('dart --version');
}
