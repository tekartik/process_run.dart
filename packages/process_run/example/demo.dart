import 'dart:async';
import 'dart:io';

import 'package:process_run/process_run.dart';

Future main() async {
  // Calling dart
  await runExecutableArguments('dart', ['--version'], verbose: true);

  // Stream the out to stdout
  await runExecutableArguments('echo', ['hello world'], verbose: true);

  // Run the command
  await runExecutableArguments('echo', ['hello world']);

  // stream the output to stderr
  await runExecutableArguments('dart', ['--version'], stderr: stderr);
}
