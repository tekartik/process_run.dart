# process_run shell API reference

Everything is exported by `package:process_run/shell.dart` unless stated
otherwise. `package:process_run/process_run.dart` re-exports `shell.dart`.

## `Shell` constructor and `ShellOptions`

`Shell({...})`, `run(script, {...})`, `runSync(script, {...})` and
`ShellOptions({...})` accept the same named parameters:

| Parameter | Default | Meaning |
| --- | --- | --- |
| `throwOnError` | `true` | throw `ShellException` when `exitCode != 0` |
| `workingDirectory` | `null` (current dir) | directory of the child processes |
| `environment` | `null` | extra vars/paths/aliases (a `Map` or a `ShellEnvironment`) |
| `includeParentEnvironment` | `true` | merge `environment` over the current shell environment; `false` uses `environment` alone |
| `runInShell` | `null` | `false`, except Windows non-`.exe` executables which use `true` |
| `stdoutEncoding`, `stderrEncoding` | `systemEncoding` | decoding of captured output (`utf8` for UTF-8 tools on Windows) |
| `stdin` | `null` | `Stream<List<int>>` forwarded to the child |
| `stdout`, `stderr` | `null` | `StreamSink<List<int>>` receiving output as produced |
| `verbose` | `true` | echo the command and stream stdout/stderr (to the sinks or the terminal) |
| `commandVerbose` | `verbose` | print `$ command` before running |
| `commentVerbose` | `false` | print script comments |
| `noStdoutResult`, `noStderrResult` | `null` | `ShellOptions` and global `runExecutableArguments` only: discard the output (result field `null`, nothing streamed); ignored by the sync variants |
| `mode` | `ProcessStartMode.normal` | `ShellOptions` only; `inheritStdio` and `detachedWithStdio` disable result capture |
| `options` | `null` | a `ShellOptions` overriding all the other parameters |

`ShellOptions` getters: `throwOnError`, `workingDirectory`, `environment`
(a `ShellEnvironment`), `runInShell`, `stdoutEncoding`, `stderrEncoding`,
`stdin`, `stdout`, `stderr`, `verbose`, `commandVerbose`, `commentVerbose`,
`noStdoutResult`, `noStderrResult`, `mode`.
`options.clone({...})` copies with overrides (`shellEnvironment:` replaces
the environment).

## `Shell` members

* `Future<List<ProcessResult>> run(String script, {ShellOnProcessCallback? onProcess})`
* `Future<ShellProcessResults> runScript(String script, {ShellCommandRunOptions? options})`
* `Future<ShellProcessResult> runCommand(ShellCommand command, {ShellCommandRunOptions? options})`
* `Future<ProcessResult> runExecutableArguments(String executable, List<String> arguments, {ShellOnProcessCallback? onProcess})`
* `List<ProcessResult> runSync(String script)`
* `ShellProcessResult runCommandSync(ShellCommand command)`
* `ProcessResult runExecutableArgumentsSync(String executable, List<String> arguments)`
* `Shell cd(String path)`, `Shell pushd(String path)`, `Shell popd()`,
  `String get path`
* `bool kill([ProcessSignal signal = ProcessSignal.sigterm])`
* `Shell cloneWithOptions(ShellOptions options)`, `ShellOptions get options`,
  `ShellContext get context`
* `Future<Shell> shellVarOverride(String name, String? value, {bool? local})`
  (writes the variable in the local or user `env.yaml`, returns a shell using
  it; see the `process-run-environment` skill)

`ShellOnProcessCallback` is `void Function(Process process)`.
`ShellCommandRunOptions({onProcess})` wraps it for `runScript`/`runCommand`.

## `ShellCommand`

* `ShellCommand(String executable, List<String> arguments)`
* `ShellCommand.parse(String line)` (splits like a script line)
* `ShellCommand.fromArguments(Iterable<String> arguments)` (first item is
  the executable)
* `executable`, `arguments`, `toCommandString()` (quoted single line,
  also `toString()`), value equality.

## Results

`ProcessResult` (from `dart:io`, re-exported): `exitCode`, `pid`,
`stdout`, `stderr` (`String` with an encoding, `List<int>` with a null
encoding, `null` with `noStdoutResult`).

Extensions from `shell.dart`:

* on `ProcessResult`: `outText`, `errText`, `outLines`, `errLines`,
  `toDebugString()`, `command` (the `ShellCommand` that produced it).
* on `List<ProcessResult>`: `outText`, `errText`, `outLines`, `errLines`
  (concatenation of all results).
* on `Process`: `outLines`, `errLines` (`Stream<String>`).

`ShellProcessResult` (returned by `runCommand`, items of `runScript`):
`exitCode`, `pid`, `stdout`, `stderr` (never null, `''` when absent),
`command`, `shell`, `processResult`, `outText`, `errText`, `outLines`,
`errLines`, `stdoutAsString`, `stderrAsString`, `stdoutAsUint8List`,
`stderrAsUint8List`.

`ShellProcessResults` (a `List<ShellProcessResult>`): the same text/bytes
helpers over all items plus `processResults` and `shell`.

## `ShellException`

Members: `message`, `shellCommand` (`ShellCommand?`), `shellProcessResult`
(`ShellProcessResult?`), `result` (`ProcessResult?`), `command`
(`ProcessCmd?`, legacy), `toDebugString()`. `toString()` is
`ShellException(<message>)`. The message contains the command, the exit
code (or the `ProcessException` text) and the working directory.

## Script helpers

* `shellArgument(String)` / `argumentToString`: quote one argument if needed
  (empty string becomes `""`).
* `shellArguments(List<String>)` / `argumentsToString`: join quoted
  arguments.
* `stringToArguments(String)` / `shellScriptLineToArguments`: split one
  line into arguments (single and double quotes handled; backslash escapes
  on Linux/macOS only).
* `shellScriptSplitLines(String script, {bool? skipComments})`: split a
  script into command lines, applying trimming, comments and continuations.
* `shellScriptLineIsComment(String line)`.
* `executableArgumentsToString(String executable, List<String> arguments)`
  and `shellExecutableArguments(...)`: build a script line.
* `shellStreamLines(Stream<List<int>>, {Encoding? encoding})`: line
  splitting stream transformer used by `ShellLinesController`.

## `ShellLinesController`

`ShellLinesController({Encoding? encoding})`: `sink`
(`StreamSink<List<int>>`, give it to `Shell(stdout:)`/`stderr:`),
`stream` (`Stream<String>` of lines), `binaryStream` (raw
`Stream<List<int>>`, give it to `Shell(stdin:)`), `write(String)`,
`writeln(String)`, `close()`, `done`, `isClosed`. The controller is
single-subscription.

## Prompt helpers

`prompt(String? text)`, `promptConfirm(String? text)` (`y`/`Y` returns
true), `promptTerminate()`: read from `sharedStdIn`. Call
`promptTerminate()` (or `sharedStdIn.terminate()`) before exiting.

## Legacy command objects (`package:process_run/cmd_run.dart`)

Prefer `Shell`. Still available:

* `ProcessCmd(String executable, List<String> arguments, {workingDirectory, environment, includeParentEnvironment = true, runInShell, stdoutEncoding, stderrEncoding, mode})`
  with mutable fields, `clone()`, `toDebugString()`.
* `DartCmd(arguments)`, `PubCmd(arguments)` (`dart pub ...`),
  `PubRunCmd(command, arguments)`, `PubGlobalRunCmd(command, arguments)`,
  `FlutterCmd(arguments)` (throws if flutter is not found),
  `PbrCmd` (`pub run build_runner`), `WebDevCmd`.
* `runCmd(ProcessCmd cmd, {ShellOptions? options, bool? verbose, bool? commandVerbose, stdin, stdout, stderr})`:
  `throwOnError` is `false` unless `options` says otherwise.
* `getDartBinVersion()` runs `dart --version` and returns a
  `pub_semver` `Version?`.
