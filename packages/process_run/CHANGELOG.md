## 1.2.4

* Allow running in a zoned environment context.

## 1.2.3

* Requires dart 3.7

## 1.2.2+1

* Special kill behavior on linux, mac and windows when using sigkill (kills all children too)
* Export `ShellOnProcessCallback`

## 1.2.1+1

* Add `ShellLinesController.binaryStream` to allow processing binary data and allow using it for stdin.
* Fix `--user` flag handling in `ds` executable.

## 1.2.0+3

* Export ShellBinCommand
* requires dart 3.5

## 1.1.0

* Remove deprecated methods

## 1.0.0+3

* add `ShellStdio` and `shellStdioLinesGrouper` to allow grouping stdout and stderr lines by zones.

## 0.14.2

* add `noStdoutResult` and `noStderrResult` to `ShellOptions` and `runExecutableArguments` to avoid out of memory for 
  very long output

## 0.14.1+3

* add `runSync` and `runExecutableArgumentsSync` to global space and to `Shell`

## 0.14.0+1

* No longer replace `\` by `\\` before splitting arguments
* Fix backslash handling when splitting a command with a different behavior on Windows and Mac/Linux 
  (backslash is not an escape character on Windows)

## 0.13.3+1

* Fix finding `flutter` on windows in unit tests
* Remove `charcode` dependency.
* Propage added errors in `ShellLinesController`

## 0.13.2

* Export `stringToArguments` in `shell.dart`

## 0.13.1

* Dart 3 only

## 0.13.0

* Dart 3 support

## 0.12.5+3

* Fix `clone` in `ShellMixin`.

## 0.12.5

* requires dart sdk 2.18
* strict-casts support

## 0.12.3+2

* Cache shellEnvironment when set
* dart 2.14 lints
* Resolve relative executable according to working directory

## 0.12.1+1

* Add `ProcessRunProcessResultExt` helper.
* Add `onProcess` callback for Shell run actions.
* Don't flush stdout/stderr in Windows release mode as it hangs

## 0.12.0+1

* `nnbd` support

## 0.11.2+8

* Add `ShellEnvironment` utility, allowing adding vars, path and alias
* Add `ds` (shell binary) executable for manipulating environment used in `Shell` from the command line
* Fix verbose non ASCII character output

## 0.11.1

* Add `ShellLinesController` utility
* Export `which` from `shell` and utilities.
* Test on all platforms using GitHub actions.

## 0.11.0+2

* More stuff in process_run: run, outLines and errLines on List<ProcessResult>

## 0.10.12+3

* Handle dart/pub binary path resolution next to flutter for SDK 2.9+
* Add `Shell.runExecutableArguments`
* Fix: `runInShell` no longer forced to true on Windows for executable with `.exe` extension

## 0.10.10

* Add `prompt`, `promptTerminate`, `promptConfirm` to `shell.dart`. Export `sharedStdIn` from package `io`

## 0.10.9+2

* Add `dartChannel`

## 0.10.8

* Add `Shell.path` property

## 0.10.7

* Add `getDartBinVersion`, `getFlutterBinVersion`, `getFlutterBinChannel` and `getPackageVersion`
* User pedantic 1.9
* Find flutter bin compared to running dart sdk

## 0.10.4+1

* Android support
* Fix shell run commands un multiple lines

## 0.10.3

* now the userEnvironment is used by default in shell. Use platformEnvironment for the raw environment.
* add shell run command to run a command with user loaded vars and paths
* add `userLoadConfigFile` to load any `.yaml` file
* add `getFlutterVersion`

## 0.10.2

* add `shell` binary allowing editing the environment file on MacOS/Windows and Linux

## 0.10.1

* add `userPaths` and `userEnvironment` access and allow overriding for finding executable and passing env variable
to callee

## 0.10.0

* feat: add Shell class and features
* try to resolve single command everywhere

## 0.9.0

* fix: which now returns the full path on linux

## 0.8.0

* Deprecate old commands helper dartCmd, pubCmd... to use constructors instead
  (DartCmd, PubCmd...)
* Add webdev and pbr command 

## 0.7.0

* add flutter command support
* add Windows support
* add which utility

## 0.6.0

* dart2 support

## 0.5.6

* supports `implicit-casts: false`

## 0.5.5

* when using io.stdout and io.stderr, flush them when running a command

## 0.5.4

* Fix handling of stdin

## 0.5.2

* fix dart2js to have a libraryRoot argument
* add dartdevc

## 0.5.1

* fix devRun

## 0.5.0

* deprecated connectStdout and connectStrerr in ProcessCmd
* add stdin, stdout, verbose and commandVerbose parameter for run

## 0.4.0

* add stdin and deprecated buggy connectStdin

## 0.3.3

* add argumentToString to handle basic quote or double quote

## 0.3.2

* fix dartdoc to add --packages argument along with the snapshot

## 0.3.0

* Add runCmd (cmd_run library)

## 0.2.0

* Add ProcessCmd

## 0.1.0

* Initial version, run and dartbin utilities
