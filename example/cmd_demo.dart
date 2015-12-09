#!/usr/bin/env dart
library command.example.command_demo;

import 'package:process_run/cmd_run.dart';

main() async {
  await run('echo', ['hello world']);

  var cmd = processCmd('echo', ['hello world']);
  await runCmd(cmd);

  await runCmd(dartCmd(['--version']));

  await runCmd(dartCmd(['my_script.dart', 'my_first_arg', 'my_second_arg']));

  print((await run('echo', ['hello world'])).stdout);
  print((await runCmd(dartCmd(['--version']))).stderr);
  print((await runCmd(dartCmd(['example/command.dart', '--version']))).stdout);
}
