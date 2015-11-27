# process_run.dart

Process run helpers for Linux/Win/Mac

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
  // Simple echo command
  // Somehow windows requires runInShell for the system commands
  bool runInShell = Platform.isWindows;

  // Run the command
  await run('echo', ['hello world'], runInShell: runInShell);

  // Stream the out to stdout
  await run('echo', ['hello world'],
      runInShell: runInShell, connectStdout: true);

  // Calling dart
  await run(dartExecutable, ['--version']);

  // stream the output to stderr
  await run(dartExecutable, ['--version'], connectStderr: true);

  // Listing global activated packages
  await run(dartExecutable, pubArguments(['global', 'list']),
      connectStdout: true);
}
````

## Limitations

As noted in the example, windows requires runInShell for system commands (echo, type)
but not for regular executables (dart, git...)
