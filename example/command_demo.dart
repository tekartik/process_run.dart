#!/usr/bin/env dart
library command.example.command_demo;

import 'package:command/command_io.dart';
import 'package:command/dartbin.dart';

main() async {
  await io.run('echo', ['hello world']);

  await io.runCmd(dartCmd(['--version']));

  await io.runCmd(dartCmd(['my_script.dart', 'my_first_arg', 'my_second_arg']));

  print((await io.run('echo', ['hello world'])).out);
  print((await io.runCmd(dartCmd(['--version']))).err);
  print((await io.runCmd(dartCmd(['example/command.dart', '--version']))).out);
}
