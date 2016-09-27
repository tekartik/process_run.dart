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

  stdout.writeln("# running normally");
  await runCmd(cmd);

  stdout.writeln("# running verbose");
  await runCmd(cmd, verbose: true);

  await stdout.flush();
  stdout.writeln("# only stream output");
  // Stream the out to stdout
  await runCmd(cmd, stdout: stdout);

  // Calling dart

  stdout.writeln("# dart --version");
  cmd = dartCmd(['--version']);
  await runCmd(cmd);

  //await stdout.flush();
  //await stderr.flush();
  stdout.writeln("# dart --version (verbose)");
  cmd = dartCmd(['--version']);
  await runCmd(cmd, verbose: true);

  //await stdout.flush();
  //await stderr.flush();

  stdout.writeln("# dart --version (stderr only)");
  // stream stderr
  // clone the command to allow other modifications
  await runCmd(cmd, stderr: stderr);

  await stdout.flush();
  stdout.writeln("# dart --version (stdout only)");
  // stream stdout
  await runCmd(cmd, stdout: stdout);

  // hello
  stdout.writeln("# hello world");
  cmd = processCmd('echo', ['hello world']);
  await runCmd(cmd);

  await runCmd(dartCmd(['--version']));

  await runCmd(dartCmd(['my_script.dart', 'my_first_arg', 'my_second_arg']));

  stdout.writeln("# hello world .stdout");
  print((await run('echo', ['hello world'])).stdout);
  print((await runCmd(dartCmd(['--version']))).stderr);
  print((await runCmd(dartCmd(['example/command.dart', '--version']))).stdout);
}
