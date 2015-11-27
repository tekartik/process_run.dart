# process_run.dart

Process run helper for Linux/Win/Mac

[![Build Status](https://travis-ci.org/tekartik/process_run.dart.svg?branch=master)](https://travis-ci.org/tekartik/process_run.dart)

## Usage

### process_run

Additional options to Process.run are
* connecting stdin
* connecting stdout
* connecting sterr

### dartbin

Helper to format dart binaries argument that works cross-platforms
* dart2js
* pub
* dartfmt
* dartanalyzer
* dartoc

### Sample usage

````
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
  await run(dartExecutable, pubArguments(['global', 'list']), connectStdout: true);
}
````