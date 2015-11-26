#!/usr/bin/env dart
library command.example.command_demo;

import 'package:command/command.dart';
import 'package:command/dartbin.dart';

main() async {
  await ioExecutor.run('echo', ['hello world']);

  var cmd = command('echo', ['hello world']);
  await ioExecutor.runCmd(cmd);

  await ioExecutor.runCmd(dartCmd(['--version']));

  await ioExecutor
      .runCmd(dartCmd(['my_script.dart', 'my_first_arg', 'my_second_arg']));

  print((await ioExecutor.run('echo', ['hello world'])).out);
  print((await ioExecutor.runCmd(dartCmd(['--version']))).err);
  print((await ioExecutor
      .runCmd(dartCmd(['example/command.dart', '--version']))).out);
}
