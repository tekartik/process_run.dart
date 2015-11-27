#!/usr/bin/env dart
library process_run.bin.demo;

import 'package:process_run/process_run.dart';
import 'package:process_run/dartbin.dart';

main() async {
  // Run the command
  await run('echo', ['hello world']);

  // Stream the out to stdout
  await run('echo', ['hello world'], connectStdout: true);

  // Calling dart
  await run(dartExecutable, ['--version']);

  // stream the output to stderr
  await run(dartExecutable, ['--version'], connectStderr: true);

  // Listing global activated packages
  await run(dartExecutable, pubArguments(['global', 'list']),
      connectStdout: true);
}
