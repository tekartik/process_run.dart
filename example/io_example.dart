#!/usr/bin/env dart
library tekartik_cmdo.example.io_example;

import 'package:cmdo/cmdo_io.dart';
import 'package:cmdo/dartbin.dart';

main() async {
  await io.run('echo', ['hello world']);

  await io.runCmd(dartCmd(['--version']));

  await io.runCmd(dartCmd(['my_script.dart', 'my_first_arg', 'my_second_arg']));

  print((await io.run('echo', ['hello world'])).out);
  print((await io.runCmd(dartCmd(['--version']))).err);
  print((await io.runCmd(dartCmd(['example/cmdo.dart', '--version']))).out);
}
