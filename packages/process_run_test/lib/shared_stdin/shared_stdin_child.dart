#!/usr/bin/env dart

/// A program reading its input through `sharedStdIn`, the way a command line
/// tool does, for test/shared_stdin_test.dart, its stdin a pipe. Compiled by
/// `compileSharedStdinChild()`, not imported; it also runs from its source
/// (`dart lib/shared_stdin/shared_stdin_child.dart <mode>`).
///
/// Prints `done` once `sharedStdIn.terminate()` returned.
library;

import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

/// Program version (`--version`).
final sharedStdinChildVersion = Version(0, 1, 0);

/// This program and the arguments to run it again: the executable when
/// compiled, dart and the script when run from its source.
List<String> get _self {
  var script = Platform.script.toFilePath();
  return script.endsWith('.dart')
      ? [Platform.resolvedExecutable, script]
      : [Platform.resolvedExecutable];
}

/// Runs this program again with [arguments], stdin from [sharedStdIn].
Future<ProcessResult> _runSelf(List<String> arguments) {
  var self = _self;
  return Shell(
    stdin: sharedStdIn,
    verbose: false,
  ).runExecutableArguments(self.first, [...self.skip(1), ...arguments]);
}

/// Runs the mode given as the first argument:
/// * `lines`: reads the lines until the end of input, prints them.
/// * `shell`: runs `cat` (below) with `Shell(stdin: sharedStdIn)`, prints its
///   output.
/// * `cat`: copies its own stdin to stdout (the child of `shell`).
/// * `terminate`: runs a command not reading its input, prints `ready`: the
///   line then written, that nobody reads, is pending at `terminate()`.
/// * `prompt`: a `prompt` at the end of input.
Future<void> main(List<String> arguments) async {
  switch (arguments.first) {
    case '--version':
      stdout.write(sharedStdinChildVersion);
      return;
    case 'lines':
      var lines = await sharedStdIn.lines().toList();
      stdout.writeln('lines: ${lines.join(',')}');
    case 'shell':
      var result = await _runSelf(['cat']);
      stdout.writeln('out: ${result.outText}');
    case 'cat':
      await stdin.forEach(stdout.add);
      return;
    case 'terminate':
      await _runSelf(['--version']);
      stdout.writeln('ready');
      // Time for the line written on `ready` to arrive.
      await Future<void>.delayed(const Duration(milliseconds: 500));
    case 'prompt':
      try {
        var text = await prompt('name');
        stdout.writeln('text: $text');
      } on StateError catch (_) {
        stdout.writeln('no input');
      }
  }
  await sharedStdIn.terminate();
  stdout.writeln('done');
}
