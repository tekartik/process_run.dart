import 'dart:io';

import 'package:path/path.dart';

import '../src/compile_test_executable.dart';
import 'child.dart';

export 'child.dart' show childVersion;

/// Compiles the child test program (`lib/child/child.dart`) for the current
/// host into `<path>/build/<linux|macos|windows>/process_run_child[.exe]`
/// when needed, returns its absolute path.
///
/// [path] is the root of the `process_run_test` package (the current
/// directory by default). An existing executable is reused when its
/// `--version` is [childVersion]: checked once per process, the calls are
/// serialized (concurrent calls compile once). [force] compiles anyway,
/// [verbose] shows the commands.
Future<String> compileChild({
  String? path,
  bool force = false,
  bool? verbose,
}) => compileTestExecutable(
  name: 'process_run_child',
  source: join('lib', 'child', 'child.dart'),
  version: childVersion,
  path: path,
  force: force,
  verbose: verbose,
);

/// The exit code of a process killed by [signal] (`-9` for `sigkill`) as
/// `Process.exitCode` reports it on Linux and macOS.
int childSignalExitCode(ProcessSignal signal) => -signal.signalNumber;
