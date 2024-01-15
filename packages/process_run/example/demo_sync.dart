import 'dart:io';

import 'package:process_run/process_run.dart';

void main() {
  // Run the command
  runExecutableArgumentsSync('echo', ['hello world']);

  // Stream the out to stdout
  runExecutableArgumentsSync('echo', ['hello world']);

  // Calling dart
  runExecutableArgumentsSync('dart', ['--version'], verbose: true);

  // stream the output to stderr
  runExecutableArgumentsSync('dart', ['--version'], stderr: stderr);
}
