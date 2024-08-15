import 'dart:async';

import 'package:process_run/shell_run.dart';
import 'package:process_run/src/prompt.dart';
import 'package:process_run/stdio.dart';

Future main() async {
  stdout.writeln(await prompt('Enter your name'));
  stdout.writeln(await promptConfirm('Action'));
  await promptTerminate();
}
