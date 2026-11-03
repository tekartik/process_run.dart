import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import '../src/compile_test_executable.dart';
import 'echo.dart';

Future<void> main() async {
  var echo = await compileEcho();
  await run('${shellArgument(echo)} --version');
}

/// Compiles the echo test program (`lib/echo/echo.dart`) for the current
/// host into `<path>/build/<linux|macos|windows>/process_run_echo[.exe]`
/// when needed, returns its absolute path (quote it with [shellArgument] in
/// a script).
///
/// [path] is the root of the `process_run_test` package (the current
/// directory by default). An existing executable is reused when its
/// `--version` is [echoVersion]: checked once per process, the calls are
/// serialized (concurrent calls compile once). [force] compiles anyway,
/// [verbose] shows the commands.
Future<String> compileEcho({String? path, bool force = false, bool? verbose}) =>
    compileTestExecutable(
      name: 'process_run_echo',
      source: join('lib', 'echo', 'echo.dart'),
      version: echoVersion,
      path: path,
      force: force,
      verbose: verbose,
    );
