# process_run_test

Test helpers for code that starts processes with
[process_run](https://pub.dev/packages/process_run): small test programs to
compile and run (an `echo` with exact stdout, stderr, exit code and stdin
behaviour, a `child` to kill, a program reading `sharedStdIn`) and two shared
test suites (`echoTests`, `shellCoreTests`). For tests only, io only (Dart VM
on Linux, macOS, Windows, with the `dart` executable to compile the
programs). Not on pub.dev.

## Getting started

```yaml
dev_dependencies:
  process_run_test:
    git:
      url: https://github.com/tekartik/process_run.dart
      path: packages/process_run_test
```

The programs are compiled (`dart compile exe`) into the `build/` folder of
the `process_run_test` package, the `path` argument: from another package,
pass the root of the dependency.

```dart
@TestOn('vm')
library;

import 'dart:isolate';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run_test/echo/compile_echo.dart';
import 'package:test/test.dart';

/// Root of the process_run_test package (pub cache or path dependency).
Future<String> processRunTestRoot() async {
  var uri = await Isolate.resolvePackageUri(
    Uri.parse('package:process_run_test/echo/echo.dart'),
  );
  return normalize(join(dirname(uri!.toFilePath()), '..', '..'));
}

void main() {
  late String echo;
  setUpAll(() async {
    echo = await compileEcho(path: await processRunTestRoot());
  });

  test('exit code and streams', () async {
    var result = await Shell(throwOnError: false, verbose: false)
        .runExecutableArguments(echo, [
          '--stdout',
          'out',
          '--stderr',
          'err',
          '--exit-code',
          '3',
        ]);
    expect(result.outText, 'out');
    expect(result.errText, 'err');
    expect(result.exitCode, 3);
  });
}
```

## What is in it

| Import | Use it for |
|---|---|
| `package:process_run_test/echo/compile_echo.dart` | `compileEcho()`: the echo program (`--stdout`, `--stderr`, `--stdout-hex`, `--stdin`, `--exit-code`, `--wait`, `--stdout-env`, `--help`) |
| `package:process_run_test/child/compile_child.dart` | `compileChild()`: a program to kill (waits, starts a chain of children, catches sigterm/sigint), `childSignalExitCode` |
| `package:process_run_test/shared_stdin/compile_shared_stdin_child.dart` | `compileSharedStdinChild()`: a program reading `sharedStdIn` (end of input, `prompt`, `terminate`) |
| `package:process_run_test/echo_test.dart` | `echoTests(EchoTestContext(echo))`: the shared echo suite, on the `Shell()` of the global `shellContext` (`supportsStdin: false`, `supportsBinaryOutput: false` skip what a shell context cannot do) |
| `package:process_run_test/shell_core_test.dart` | `shellCoreTests(shellContext)`: the shared `Shell` suite, real or in memory (`ShellContextMemory`) |

## Common mistakes

- Calling `compileEcho()` (no `path`) outside the `process_run_test` package root: it compiles relative to the current
  directory.
- Putting the returned path in a `shell.run('...')` script without `shellArgument(path)` (it is absolute and may hold
  spaces); `runExecutableArguments(path, [...])` takes it as is.
- Driving a program with `dart:io` `Process.start`: use `Shell` (`runExecutableArguments`, `onProcess`, `kill`) and
  `ShellLinesController` for its stdin and stdout, as `test/child_test.dart` and `test/shared_stdin_test.dart` do.

More in the [process-run-test-setup skill](skills/process-run-test-setup/SKILL.md).
