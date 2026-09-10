---
name: process-run-shell
description: >-
  Use when running external commands or multi-line scripts from Dart with
  package:process_run (Shell, run, runSync, runExecutableArguments,
  runExecutableArgumentsSync, ShellOptions, ShellException, ShellCommand,
  runCommand, runScript, outText/outLines/errText/errLines, verbose,
  commandVerbose, throwOnError, workingDirectory, cd/pushd/popd,
  shellArgument/shellArguments quoting, stdout/stderr sinks,
  ShellLinesController, stdin, kill, noStdoutResult). Covers script syntax,
  executable resolution, result capture and error handling on Linux, macOS
  and Windows.
---

# process_run shell: run commands portably

`package:process_run/shell.dart` runs one or many command lines from Dart on
Linux, macOS and Windows with the same script text. Each line is one
executable resolved with `which` semantics, started through `dart:io`
`Process` and returned as a `ProcessResult`. VM only (`dart:io`): Dart CLI
and Flutter desktop/mobile, not web.

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var shell = Shell();
  await shell.run('''
# Comments are allowed
dart --version
git status
''');
}
```

## Guidelines

### Choosing the entry point

* `Shell()` then `shell.run(script)` is the primary API. Use the global
  `run(script)` for one-off calls; it builds a `Shell` with the same
  parameters. Both default to `verbose: true` (command echoed, stdout and
  stderr streamed to the terminal) and `throwOnError: true`.
* `shell.runExecutableArguments(executable, arguments)` runs one command from
  an explicit argument list (no quoting/splitting), with the shell options.
  Prefer it over string building when arguments come from variables.
* The **global** `runExecutableArguments(...)` and
  `runExecutableArgumentsSync(...)` (also in `shell.dart`) default to
  `verbose: false` and `throwOnError: false`, unlike `run`. Check `exitCode`
  yourself or pass `throwOnError: true`.
* `runSync` / `runExecutableArgumentsSync` (global and on `Shell`) block until
  the child exits, cannot receive `stdin`, cannot be `kill()`ed and ignore
  `noStdoutResult`/`noStderrResult`. Use them in tests and tiny scripts only.
* A `Shell` is immutable: `cd`, `pushd`, `popd`, `cloneWithOptions` return a
  new `Shell`. `shell.options` exposes the `ShellOptions` in use and
  `shell.options.clone(...)` derives a modified copy.
* `Shell(options: ShellOptions(...))` overrides every other constructor
  parameter. Keep one `ShellOptions` when you create many shells.

### Script syntax (`run`, `runSync`, `runScript`)

* One command per line. Lines are trimmed; empty lines are ignored; lines
  starting with `#`, `// ` or `/// ` are comments (printed only with
  `commentVerbose: true`).
* A line ending with ` ^` or ` \` (space then the character; in a Dart
  string write `' \\'`) continues on the next line.
* No pipes, redirections, `&&`, variables or loops: each line is exactly one
  executable plus arguments. Do that logic in Dart.
* The first word is the executable. A plain name is searched in the shell
  environment paths (`PATH` plus user config paths and the running dart SDK
  `bin` directory) and aliases; a relative path is resolved from
  `workingDirectory`; an absolute path is used as is. On Windows the
  `PATHEXT` extensions (`.exe`, `.bat`, `.cmd`...) are tried.
* Quote arguments containing spaces with double or single quotes, or build the
  line with `shellArgument(value)` / `shellArguments(list)`. On Windows the
  backslash is not an escape character (`C:\dir` is fine); on Linux/macOS a
  bare backslash escapes the next character, so use `shellArgument` for paths
  with backslashes.
* `ShellCommand.parse(line)` and `ShellCommand(executable, arguments)`
  build a single command object; `shell.runCommand(command)` runs it and
  returns a `ShellProcessResult`. `shellScriptSplitLines(script)` and
  `shellScriptLineToArguments(line)` expose the parser.
* Leave `runInShell` null. It defaults to false, except on Windows where any
  executable without a `.exe` extension (built-ins like `echo`, `.bat`
  scripts) is run through the shell automatically.

### Output and results

* `run` returns `List<ProcessResult>` (one per command, in order). Import of
  `shell.dart` adds `outText`, `errText`, `outLines`, `errLines` on the list
  (all commands concatenated) and on each `ProcessResult`. `outText` joins
  lines with `\n` and has no trailing newline; `result.stdout` is the raw
  `String` decoded with `stdoutEncoding`.
* `shell.runScript(script)` returns `ShellProcessResults`
  (a `List<ShellProcessResult>`) with the same helpers plus
  `stdoutAsString`, `stderrAsString`, `stdoutAsUint8List`,
  `stderrAsUint8List` and `processResults` (the raw list). Prefer it when you
  need the exact bytes or the executed `command`.
* `verbose: false` captures silently; output is still available in the
  results. `commandVerbose: true` with `verbose: false` prints only the
  `$ command` line.
* Pass `stdout:` / `stderr:` (`StreamSink<List<int>>`) to receive the child
  output as it is produced (with `verbose: true` it goes to the sink instead
  of the terminal). Use `ShellLinesController` to get a `Stream<String>` of
  lines: `Shell(stdout: controller.sink)`, listen to `controller.stream`,
  `controller.close()` when done.
* Output is always buffered in the result. For a command whose output you
  do not need at all, `ShellOptions(noStdoutResult: true)` /
  `noStderrResult: true` (or the same named parameters of the global
  `runExecutableArguments`) discard it: the result field is null and
  nothing is streamed to the terminal or to the sinks either. Ignored by
  the sync variants.
* Default encoding is `systemEncoding`. Pass `stdoutEncoding: utf8` (and
  `stderrEncoding`) when the tool prints UTF-8 on Windows.
* `ShellOptions(mode: ProcessStartMode.inheritStdio)` hands the terminal to
  the child (interactive tools); nothing is captured in that mode.

### Errors

* With `throwOnError: true` (default) a non-zero exit code throws
  `ShellException`. Catch it: `e.message`, `e.shellCommand` (the parsed
  command), `e.result` (`ProcessResult?`, null when the executable could not
  be started), `e.shellProcessResult`, and `e.toDebugString()` (message,
  directory, command, exit code, out and err).
* A missing executable or a missing `workingDirectory` also throws
  `ShellException` (wrapping the `ProcessException`) with `result == null`.
* Use `Shell(throwOnError: false)` when a non-zero exit code is expected
  (`grep`, `lsof`, `git diff --exit-code`) and read `result.exitCode`.
* `run` executes the script sequentially and stops at the first failing
  command when `throwOnError` is true; the results of the earlier commands
  are lost (only the exception is returned). Split the script if you need
  partial results.
* Never build a `ShellException` yourself; the factory constructors are for
  the package.

### Working directory

* `Shell(workingDirectory: path)` or `shell.cd(path)`. A relative `cd` path is
  resolved against the current shell directory. `shell.path` returns the
  effective directory.
* `shell = shell.pushd('sub')` then `shell = shell.popd()` mimic the shell
  builtins; `popd()` throws `StateError` when there is nothing to pop. Always
  reassign the returned shell.
* Relative script paths (`dart tool/build.dart`) are relative to the shell
  `workingDirectory`, not to the Dart process directory.

### stdin, long running processes and kill

* Feed input with `Shell(stdin: stream)` where the stream is a
  `Stream<List<int>>`. To forward the user's terminal input use
  `sharedStdIn` and call `await sharedStdIn.terminate()` before the program
  ends (otherwise it never exits). To feed generated text use a
  `ShellLinesController`: `Shell(stdin: input.binaryStream)`,
  `input.writeln('...')`, `input.close()`.
* `shell.kill([ProcessSignal signal])` kills the running command (default
  `sigterm`); the pending `run` future completes with `ShellException`.
  `ProcessSignal.sigkill` additionally kills child processes (`pkill -P` on
  Linux/macOS, `taskkill /t` on Windows), needed for servers such as
  `dhttpd`.
* `run(script, onProcess: (process) {...})` gives the `dart:io` `Process`
  of each command as it starts (pid, manual kill).
* Calls on one `Shell` are serialized with a lock: two concurrent
  `shell.run` on the same instance execute one after the other. Create
  distinct shells for parallel work.

### Platform notes

* Windows built-ins (`echo`, `dir`, `type`, `del`) work because they are run
  in the shell; prefer `dart:io` `File`/`Directory` for file operations that
  must be portable.
* Flutter macOS apps must disable App Sandbox in the entitlements files to
  start processes.
* `sudo` on Linux: alias `sudo` to `sudo --stdin` and pass
  `stdin: sharedStdIn` so the password prompt works.

## Examples

### Run a script and read the output

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var shell = Shell(verbose: false);
  var results = await shell.run('''
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
''');
  var branch = results[0].outText.trim();
  var commit = results.last.outText.trim();
  print('$branch@$commit');

  // All lines of all commands
  for (var line in results.outLines) {
    print(line);
  }
}
```

### Arguments from variables, quoting

```dart
import 'package:process_run/shell.dart';

Future<void> commit(String message, List<String> files) async {
  var shell = Shell();
  // Explicit argument list: nothing to quote.
  await shell.runExecutableArguments('git', ['add', ...files]);
  // Script line: quote what may contain spaces.
  await shell.run('git commit -m ${shellArgument(message)}');
  // Equivalent using a ShellCommand.
  await shell.runCommand(ShellCommand('git', ['commit', '-m', message]));
}
```

### Handle failures

```dart
import 'package:process_run/shell.dart';

Future<bool> hasChanges() async {
  var shell = Shell(verbose: false, throwOnError: false);
  var result = await shell.runExecutableArguments('git', [
    'diff',
    '--quiet',
  ]);
  return result.exitCode != 0;
}

Future<void> deploy() async {
  try {
    await run('firebase deploy');
  } on ShellException catch (e) {
    print('deploy failed: ${e.message}');
    print('exit code: ${e.result?.exitCode}');
    print(e.toDebugString());
    rethrow;
  }
}
```

### Working directory, pushd/popd

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var shell = Shell();
  await shell.cd('packages/app').run('dart pub get');

  shell = shell.pushd('packages/lib');
  await shell.run('dart test');
  shell = shell.popd();
  print(shell.path); // back to the original directory
}
```

### Multi-line command and comments

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  await run('''
# Build for the web (comment printed only with commentVerbose: true)
dart compile js -o build/main.js \\
  --minify \\
  web/main.dart
''', commentVerbose: true);
}
```

### Stream lines and stop early

```dart
import 'dart:async';

import 'package:process_run/shell.dart';

Future<void> main() async {
  var controller = ShellLinesController();
  var shell = Shell(stdout: controller.sink, verbose: false);
  late StreamSubscription<String> subscription;
  subscription = controller.stream.listen((line) {
    print('server: $line');
    if (line.contains('Serving at')) {
      shell.kill();
      subscription.cancel();
    }
  });
  try {
    await shell.run('dart run dhttpd --port 8080');
  } on ShellException catch (_) {
    // Thrown because the process was killed.
  } finally {
    controller.close();
  }
}
```

### Feed stdin

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var input = ShellLinesController();
  var shell = Shell(stdin: input.binaryStream, verbose: false);
  var done = shell.run('sort');
  input.writeln('b');
  input.writeln('a');
  input.close();
  var results = await done;
  print(results.outLines.toList()); // [a, b]
}
```

### Options object, clone, sync run

```dart
import 'dart:convert';

import 'package:process_run/shell.dart';

void main() {
  var options = ShellOptions(
    verbose: false,
    throwOnError: false,
    stdoutEncoding: utf8,
  );
  var shell = Shell(options: options);
  var quiet = shell.cloneWithOptions(options.clone(commandVerbose: true));

  // Synchronous: no stdin, no kill, blocks the isolate.
  var result = quiet.runExecutableArgumentsSync('dart', ['--version']);
  print('${result.exitCode}: ${result.outText}');
}
```

## Common mistakes

* Writing `cmd1 | cmd2`, `cmd > file`, `cd dir` or `export VAR=1` in a
  script: each line must be one executable. Use `shell.cd`, `dart:io` files
  and `Shell(environment: ...)` instead.
* Expecting the global `runExecutableArguments` to throw on failure or print
  output: it is silent and non-throwing by default, unlike `run`.
* Forgetting to reassign `shell = shell.cd(...)` / `pushd` / `popd`.
* Using `result.stdout` as a `List<int>`: it is a `String` unless
  `stdoutEncoding: null` was passed to a `ShellOptions`.
* Passing `noStdoutResult: true` together with a `stdout:` sink and
  expecting the sink to receive the output: the output is dropped.
* Reading `e.result!.exitCode` in a `ShellException` handler: `result` is
  null when the executable was not found or the directory does not exist.
* Leaving a `ShellLinesController` open or never calling
  `sharedStdIn.terminate()`: the program does not exit.
* Reusing one `Shell` for parallel `run` calls and expecting concurrency; they
  are serialized.

## More

See [references/api.md](references/api.md) for the `ShellOptions`
parameter table, the result and exception members, `ShellCommand`, and the
lower level `ProcessCmd`/`runCmd` API of `package:process_run/cmd_run.dart`.
