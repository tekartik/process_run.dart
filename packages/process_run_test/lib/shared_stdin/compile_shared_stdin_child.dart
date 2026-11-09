import 'package:path/path.dart';

import '../src/compile_test_executable.dart';
import 'shared_stdin_child.dart';

export 'shared_stdin_child.dart' show sharedStdinChildVersion;

/// Compiles the shared stdin test program
/// (`lib/shared_stdin/shared_stdin_child.dart`) for the current host into
/// `<path>/build/<linux|macos|windows>/process_run_shared_stdin_child[.exe]`,
/// returns its absolute path.
///
/// Compiled on every call, unlike `compileChild()`: the program embeds
/// process_run's `sharedStdIn`, a binary kept while its version is the same
/// would test an older process_run. Call it once, in a `setUpAll`.
///
/// [path] is the root of the `process_run_test` package (the current
/// directory by default), [verbose] shows the commands.
Future<String> compileSharedStdinChild({String? path, bool? verbose}) =>
    compileTestExecutable(
      name: 'process_run_shared_stdin_child',
      source: join('lib', 'shared_stdin', 'shared_stdin_child.dart'),
      version: sharedStdinChildVersion,
      path: path,
      force: true,
      verbose: verbose,
    );
