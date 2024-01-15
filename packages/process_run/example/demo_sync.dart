import 'dart:io';

import 'package:process_run/process_run.dart';

void main() {
  var shell = Shell();
  // This is a synchronous call and will block until the child process terminates.
  var results = shell.runSync('echo "Hello world"');
  var result = results.first;
  print('output: "${result.outText.trim()}" exitCode: ${result.exitCode}');
  // should display: output: "Hello world" exitCode: 0

  // Run the command
  runExecutableArgumentsSync('echo', ['hello world']);

  // Stream the out to stdout
  runExecutableArgumentsSync('echo', ['hello world']);

  // Calling dart
  runExecutableArgumentsSync('dart', ['--version'], verbose: true);

  // stream the output to stderr
  runExecutableArgumentsSync('dart', ['--version'], stderr: stderr);
}
