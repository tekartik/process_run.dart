#!/usr/bin/env dart
library command.example.command_demo;

import 'package:command/command.dart';
import 'package:command/command_dartbin.dart';

main() async {
  await run('echo', ['hello world']);

  var cmd = command('echo', ['hello world']);
  await runCmd(cmd);

  await runCmd(dartCmd(['--version']));

  await runCmd(dartCmd(['my_script.dart', 'my_first_arg', 'my_second_arg']));

  print((await run('echo', ['hello world'])).out);
  print((await runCmd(dartCmd(['--version']))).err);
  print((await runCmd(dartCmd(['example/command.dart', '--version']))).out);
}
