---
name: process-run-test-setup
description: >-
  Use when testing code that spawns processes or implements a process_run
  ShellContext, with the process_run_test helper package: compileEcho() to
  build the process_run_echo test executable, compileChild() to build the
  process_run_child program for kill and signal tests (process trees,
  explicit exit codes on sigterm/sigint), compileSharedStdinChild() for the
  sharedStdIn program (end of input, prompt, terminate, compiled and as a
  dart run script), driving these programs with Shell and
  ShellLinesController (not dart:io Process.start), EchoTestContext and
  echoTests(context) for the shared echo suite, shellCoreTests(shellContext)
  for the shared Shell suite on the io or memory context (shellContext,
  shellContextMemory, ShellContextMemory), and the echo command options
  (--stdout, --stderr, --stdout-hex, --stderr-hex, --stdin, --exit-code,
  --write-line, --wait, --stdout-env, --all-env, --version).
---

# process_run test helpers (process_run_test)

`process_run_test` is the test support package of `process_run`: a tiny `echo`
program you compile and spawn to get exactly the stdout, stderr, exit code and
stdin behaviour a test needs, plus two shared test suites that any
implementation can run against itself. Nothing here is meant to ship in an
application.

## Guidelines

* Dependency (git only, not on pub.dev), always in `dev_dependencies`:
  ```yaml
  dev_dependencies:
    process_run_test:
      git:
        url: https://github.com/tekartik/process_run.dart
        path: packages/process_run_test
  ```
  It brings `process_run` (pub.dev), `args`, `path`, `pub_semver` and `test`.
  Inside the repo it resolves `process_run` through a `dependency_overrides`
  path to the sibling package; a consumer gets the published one.
* Everything is `dart:io` based: start such a test file with
  `@TestOn('vm')` + `library;` and run it with `dart test`.
* Drive the test programs with `Shell` (`runExecutableArguments`,
  `throwOnError: false`), a `ShellLinesController` for their stdin
  (`binaryStream`, `write`, `close()` = end of input) and one for their
  stdout lines (`sink`, `stream`), `onProcess` for the `Process`, never
  `dart:io` `Process.start`: see the process-run-shell skill, "Driving a
  program"; `test/child_test.dart` and `test/shared_stdin_test.dart` show
  it.
* Public entry points (five, plus the echo, child and shared stdin child
  sources):
  * `package:process_run_test/echo/compile_echo.dart`: `Future<String>
    compileEcho({String? path, bool force = false, bool? verbose})`.
  * `package:process_run_test/child/compile_child.dart`: `Future<String>
    compileChild({String? path, bool force = false, bool? verbose})`,
    `childVersion`, `int childSignalExitCode(ProcessSignal signal)` (`-9`
    for `sigkill`, the exit code of a killed process on Linux and macOS).
  * `package:process_run_test/shared_stdin/compile_shared_stdin_child.dart`:
    `Future<String> compileSharedStdinChild({String? path, bool? verbose})`,
    `sharedStdinChildVersion`.
  * `package:process_run_test/echo_test.dart`: `EchoTestContext` and
    `void echoTests(EchoTestContext testContext)`.
  * `package:process_run_test/shell_core_test.dart`:
    `void shellCoreTests(ShellContext shellContext)`.
  * `package:process_run_test/echo/echo.dart` is the echo `main` itself; it is
    compiled, not imported. `lib/src/process_run_import.dart` is internal:
    import `package:process_run/shell.dart` instead.
* `compileEcho()` runs `dart compile exe lib/echo/echo.dart -o
  <path>/build/<linux|macos|windows>/process_run_echo[.exe]` and returns that
  absolute path. **It compiles relative to `path` (the current directory when
  `path` is null), so `path` must be the root of the `process_run_test`
  package checkout.** From another package, resolve it once with
  `Isolate.resolvePackageUri(Uri.parse('package:process_run_test/echo/echo.dart'))`
  and pass the package root as `path`. The binary is written to `build/` inside
  that same directory (so inside the pub cache for a git dependency); compile
  it once in a `setUpAll`. The result is cached: an existing binary whose
  `--version` matches `echoVersion` is reused, `force: true` recompiles,
  `verbose: true` shows the compile command.
* `compileEcho()` and `compileChild()` are serialized (a `Lock`: concurrent
  calls compile once) and check an existing binary once per process.
* The child program (`compileChild()`, `build/<os>/process_run_child[.exe]`,
  same `path` rule) is the process to kill: it waits (`--wait <ms>`, 60 s by
  default, then exits with `--exit-code <n>`), starts a chain of
  descendants with `--depth <n>` (same options, one level less), and writes
  `ready <pid>` once it and its descendants are started (theirs first, so
  `ready <rootPid>` is the last line: wait for it, the lines give the pids of
  the tree). `--sigterm-exit-code <n>` and `--sigint-exit-code <n>` catch the
  signal, write `signal SIGTERM` / `signal SIGINT` and exit with `n`;
  `--ignore-sigterm` catches it and keeps running (the sigkill fallback of
  `Shell.kill()`). Sigterm cannot be caught on Windows, and sigkill nowhere:
  check `childSignalExitCode(ProcessSignal.sigkill)` (`-9`) on Linux and
  macOS, a non zero code on Windows. Read the lines with
  `Shell(stdout: ShellLinesController().sink)` and get the `Process` (its
  `exitCode`) with `onProcess`; `test/child_test.dart` shows the pattern.
* The shared stdin child (`compileSharedStdinChild()`,
  `build/<os>/process_run_shared_stdin_child[.exe]`, same `path` rule) reads
  its input through `sharedStdIn` like a tool and prints `done` once
  `sharedStdIn.terminate()` returned. Modes (first argument): `lines` (reads
  until the end of input, prints `lines: a,b`), `shell` (runs itself as
  `cat` with `Shell(stdin: sharedStdIn)`, prints `out: <its output>`), `cat`,
  `terminate` (prints `ready`, a line then written is pending, unread, at
  `terminate()`), `prompt` (`prompt('name')` at the end of input, prints
  `no input` on the `StateError`), `--version`. **Compiled on every call**,
  unlike echo and child: it embeds process_run, a binary reused while its
  version is the same would test an older process_run. It also runs from its
  source (`dart run lib/shared_stdin/shared_stdin_child.dart <mode>`): a
  program embedding process_run is tested both ways, as
  `test/shared_stdin_test.dart` does (one group each).
* Quote the returned path with `shellArgument(echoPath)` before putting it in a
  `shell.run('...')` script (it is absolute and may contain spaces); pass it
  raw to `runExecutableArguments(echoPath, [...])`.
* echo options, all optional and combinable: `--stdout <text>` /
  `-o`, `--stderr <text>` / `-e`, `--stdout-hex <hex>` / `-p` and
  `--stderr-hex <hex>` / `-f` (raw bytes, read them with
  `stdoutEncoding: null` / `stderrEncoding: null`), `--stdin` / `-i` (echo the
  first stdin line to stdout), `--write-line` / `-l` (add a trailing newline),
  `--exit-code <n>` / `-x` (a non numeric value crashes with exit code 255),
  `--wait <ms>`, `--stdout-env <VAR>` (echo an environment variable),
  `--all-env` (the whole `ShellEnvironment` as pretty json), `--version`,
  `--help`. Remaining positional arguments are written as lines to stdout.
  With no argument at all it exits 0 having written nothing.
* `echoTests(EchoTestContext(echoPath))` defines the shared echo suite
  (stdout, stderr, binary output, environment, stdin, exit codes, crash)
  inside the current `group`. Use `EchoTestContext.lazy(() => echo)` when the
  path is only known in `setUpAll`, since `echoTests` runs at collection time.
  Run it to validate a `process_run` change, or as a smoke test that spawning
  processes works in your environment.
* `shellCoreTests(shellContext)` defines the shared `Shell` suite
  (`runCommand`, `runScript`, `run`, `ShellCommand.parse`, `outText`,
  `processExecutableArguments`, zoned `ShellEnvironment` vars). Pass the
  platform `shellContext` (real processes) or `ShellContextMemory()` /
  `shellContextMemory` (in memory, no process spawned, safe on any platform),
  both from `package:process_run/utils/shell_context.dart`. A memory run is
  usually wrapped in `shellContextMemory.runZoned(() async =>
  shellCoreTests(shellContext))` so the zoned context is the memory one.
  Implementing your own `ShellContext`? Run this suite against it.
* The `example/` directory of the package holds runnable demos of
  `package:process_run/stdio.dart` line grouping
  (`shellStdioLinesGrouper.runZoned(...)`), useful when debugging interleaved
  stdout/stderr output of concurrent tasks: `dart run
  example/stdout_lines_grouper_example1.dart`.
* Anti-patterns: depending on `process_run_test` at runtime; calling
  `compileEcho()` from a working directory that is not the package root;
  hard coding `build/linux/process_run_echo` instead of using the returned
  path; running these tests on the web or in a sandbox without a Dart SDK
  (the compile step needs `dart`).

## Examples

### Run the shared echo suite from your own package

```dart
@TestOn('vm')
library;

import 'dart:isolate';

import 'package:path/path.dart';
import 'package:process_run_test/echo/compile_echo.dart';
import 'package:process_run_test/echo_test.dart';
import 'package:test/test.dart';

/// Root of the process_run_test package in the pub cache or in a path dep.
Future<String> processRunTestPackageRoot() async {
  var uri = await Isolate.resolvePackageUri(
    Uri.parse('package:process_run_test/echo/echo.dart'),
  );
  // <root>/lib/echo/echo.dart -> <root>
  return normalize(join(dirname(uri!.toFilePath()), '..', '..'));
}

void main() {
  late String echo;
  setUpAll(() async {
    echo = await compileEcho(path: await processRunTestPackageRoot());
  });
  echoTests(EchoTestContext.lazy(() => echo));
}
```

### Use the echo executable in your own tests

```dart
@TestOn('vm')
library;

import 'dart:async';

import 'package:process_run/shell.dart';
import 'package:process_run_test/echo/compile_echo.dart';
import 'package:test/test.dart';

void main() {
  late String echo;
  late Shell shell;
  setUpAll(() async {
    echo = await compileEcho();
    shell = Shell(options: ShellOptions(throwOnError: false, verbose: false));
  });

  test('exit code and streams', () async {
    var result = await shell.runExecutableArguments(echo, [
      '--stdout',
      'out',
      '--stderr',
      'err',
      '--exit-code',
      '123',
    ]);
    expect(result.stdout, 'out');
    expect(result.stderr, 'err');
    expect(result.exitCode, 123);
  });

  test('binary output', () async {
    var binShell = shell.cloneWithOptions(ShellOptions(stdoutEncoding: null));
    var result = await binShell.runExecutableArguments(echo, [
      '--stdout-hex',
      '010203',
    ]);
    expect(result.stdout, [1, 2, 3]);
  });

  test('stdin', () async {
    var inCtrl = StreamController<List<int>>();
    var stdinShell = shell.cloneWithOptions(ShellOptions(stdin: inCtrl.stream));
    var resultFuture = stdinShell.runExecutableArguments(echo, ['--stdin']);
    inCtrl.add('in'.codeUnits);
    await inCtrl.close();
    expect((await resultFuture).stdout, 'in');
  });

  test('in a script', () async {
    // Absolute path: quote it.
    await shell.run('${shellArgument(echo)} --stdout hello --write-line');
  });
}
```

### Run the shared shell suite on the real and the memory context

```dart
import 'package:process_run/utils/shell_context.dart';
import 'package:process_run_test/shell_core_test.dart';
import 'package:test/test.dart';

Future<void> main() async {
  group('io', () {
    shellCoreTests(shellContext);
  });
  group('memory', () {
    // Everything inside the zone sees the memory shell context.
    shellContextMemory.runZoned(() async {
      shellCoreTests(shellContext);
    });
  });
}
```

### Validate your own ShellContext implementation

```dart
import 'package:process_run/utils/shell_context.dart';
import 'package:process_run_test/shell_core_test.dart';

void defineTests(ShellContext myContext) {
  // The suite only uses shell(), newShellEnvironment(), copyWith() and
  // runZoned(): a context that passes it behaves like the platform one.
  shellCoreTests(myContext);
}
```

### Commands

```bash
# From the process_run_test package itself
dart test                                   # compiles echo, runs every suite
dart run example/stdio_lines_grouper_example.dart
```
