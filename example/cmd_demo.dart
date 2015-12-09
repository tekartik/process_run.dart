#!/usr/bin/env dart
library command.example.command_demo;

import 'package:process_run/cmd_run.dart';
import 'dart:io';

main() async {
  // Simple echo command
  // Somehow windows requires runInShell for the system commands
  bool runInShell = Platform.isWindows;

  // Run the command
  ProcessCmd cmd = processCmd('echo', ['hello world'], runInShell: runInShell);
  await runCmd(cmd);
  // Stream the out to stdout
  await runCmd(cmd..connectStdout = true);

  // Calling dart
  cmd = dartCmd(['--version']);
  await runCmd(cmd);

  // stream stderr
  // clone the command to allow other modifications
  await runCmd(cmd.clone()..connectStderr = true);
  // stream stdout
  await runCmd(cmd.clone()..connectStdout = true);

  // hello
  cmd = processCmd('echo', ['hello world']);
  await runCmd(cmd);

  await runCmd(dartCmd(['--version']));

  await runCmd(dartCmd(['my_script.dart', 'my_first_arg', 'my_second_arg']));

  print((await run('echo', ['hello world'])).stdout);
  print((await runCmd(dartCmd(['--version']))).stderr);
  print((await runCmd(dartCmd(['example/command.dart', '--version']))).stdout);
}
