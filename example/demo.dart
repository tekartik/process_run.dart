import 'dart:io';

import 'package:process_run/process_run.dart';
import 'package:process_run/dartbin.dart';

main() async {
  // Simple echo command
  // Somehow windows requires runInShell for the system commands
  bool runInShell = Platform.isWindows;

  // Run the command
  await run('echo', ['hello world'], runInShell: runInShell);

  // Stream the out to stdout
  await run('echo', ['hello world'], runInShell: runInShell, stdout: stdout);

  // Calling dart
  await run(dartExecutable, ['--version']);

  // stream the output to stderr
  await run(dartExecutable, ['--version'], stderr: stderr);
}
