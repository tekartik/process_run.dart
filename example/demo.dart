import 'dart:async';
import 'dart:io';

import 'package:process_run/process_run.dart';

Future main() async {
  // Run the command
  await run('echo', ['hello world']);

  // Stream the out to stdout
  await run('echo', ['hello world']);

  // Calling dart
  await run('dart', ['--version'], verbose: true);

  // stream the output to stderr
  await run('dart', ['--version'], stderr: stderr);
}
