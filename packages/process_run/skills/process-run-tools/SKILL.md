---
name: process-run-tools
description: >-
  Use when locating executables or SDK information with package:process_run:
  which/whichSync, dartExecutable, dartSdkBinDirPath, dartSdkDirPath,
  dartVersion, dartChannel, getDartBinVersion, flutterExecutablePath,
  flutterDartExecutablePath, isFlutterSupported, getFlutterBinVersion,
  getFlutterBinChannel, userHomePath, userAppDataPath, pubCacheBinPath,
  dartInstallBinPath, DartToolPaths, getPackageVersion,
  prompt/promptConfirm/promptTerminate, sharedStdIn, the zone aware
  stdout/stderr of package:process_run/stdio.dart and
  shellStdioLinesGrouper, and the legacy ProcessCmd/DartCmd/runCmd API of
  package:process_run/cmd_run.dart.
---

# process_run tools: which, dart/flutter helpers, stdio

Besides `Shell`, `package:process_run` ships small helpers to find
executables the way a shell does, to know which Dart and Flutter SDK are
available, to read the user home/config directories, to prompt on the
terminal and to keep the output of concurrent scripts readable. All of them
need `dart:io` (Dart VM, Flutter desktop/mobile; not web).

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  print(await which('git')); // /usr/bin/git or null
  print(dartExecutable); // running dart VM path
  print(flutterExecutablePath); // null when flutter is not installed
  print(dartVersion); // 3.12.0
}
```

## Guidelines

### Finding executables

* `whichSync(name)` / `await which(name)` return the absolute path of an
  executable or `null`. Import `package:process_run/shell.dart` (or the
  smaller `package:process_run/which.dart`). They search the current shell
  environment paths: `PATH`, the user config paths, the running dart SDK
  `bin` directory. On Windows the `PATHEXT` extensions are tried, so
  `whichSync('flutter')` returns `flutter.bat`.
* `name` must be a bare name (`git`, `flutter`), never a path: any string
  containing a directory separator returns `null`.
* `whichSync(name, environment: {'PATH': dir})` searches a given map on top
  of the current environment; add `includeParentEnvironment: false` to
  search only that map. `ShellEnvironment().whichSync(name)` does the same
  for an environment object.
* Use `which` to give a clear error before running a tool
  (`if (await which('firebase') == null) throw StateError('install firebase')`)
  rather than catching the `ShellException` of a failed run.
* `dartBinFileName` (`dart` or `dart.exe`) helps building paths by hand.

### Dart SDK

* `dartExecutable` (`String?`) is the running VM (`Platform.resolvedExecutable`
  when it is `dart`, else `which('dart')`); `dartSdkBinDirPath` and
  `dartSdkDirPath` derive from it. Use `dartExecutable` to spawn another
  Dart process with the same SDK, or simply write `dart ...` in a script:
  the SDK `bin` directory is always first in the shell paths.
* `dartVersion` (a `pub_semver` `Version`) and `dartChannel` (`'stable'`,
  `'beta'`, `'dev'`, `'master'`, compare with `dartChannelStable`...) are
  parsed from `Platform.version` and cost nothing. `getDartBinVersion()`
  (`package:process_run/cmd_run.dart`) runs `dart --version` and returns
  `Version?`; use it only for a `dart` found elsewhere.
* `getPackageVersion({String? dir})` from
  `package:process_run/package/package.dart` reads `version:` of the
  `pubspec.yaml` in `dir` (default `.`) as a `Version?`, `null` when absent.

### Flutter SDK

* `flutterExecutablePath` (`String?`) is `whichSync('flutter')` cached for
  the process; `isFlutterSupported` / `isFlutterSupportedSync` are
  `flutterExecutablePath != null`. `flutterDartExecutablePath` is the
  `dart` bundled in that flutter (`bin/cache/dart-sdk/bin/dart`).
* `await getFlutterBinVersion()` (`Version?`) and
  `await getFlutterBinChannel()` (`String?`) run `flutter --version` once
  and cache it; both return `null` without flutter.
* When the current program runs on the flutter-bundled dart, the flutter
  `bin` directory is prepended to the shell paths, so `flutter` scripts
  work without configuration.
* Skip flutter-specific work with `if (!isFlutterSupported) return;` instead
  of catching errors.

### User directories

* `userHomePath`: `HOME` (`USERPROFILE` on Windows), `'~'` when neither is
  set. `userAppDataPath`: `%APPDATA%` on Windows, `~/.config` elsewhere.
* `pubCacheBinPath`: where `dart pub global activate` puts its binstubs
  (`PUB_CACHE`, else `%LOCALAPPDATA%\Pub\Cache\bin` or `~/.pub-cache/bin`).
  `dartInstallBinPath`: where `dart install` puts its executables
  (`DART_DATA_HOME`, else `%LOCALAPPDATA%\Dart`, `~/Library/Application Support/Dart`
  or `$XDG_STATE_HOME`/`~/.local/state/Dart`, then `install/bin`). Also
  `pubCachePath`, `dartDataHomePath`, `dartInstallPath`, and
  `DartToolPaths(os: DartToolOs.windows, environment: {...})` to compute them for
  another platform or environment (`pathIndexOf`/`isDirOnPath` check `PATH`).
  Both honor the `TEKARTIK_PROCESS_RUN_USER_HOME_PATH` and
  `TEKARTIK_PROCESS_RUN_USER_APP_DATA_PATH` overrides. Use them with
  `package:path` `join` to locate tool configuration files.

### Terminal prompts

* `await prompt('Enter your name')` returns a line, `await promptConfirm('Delete it')`
  returns `true` for `y`/`Y`. Both read `sharedStdIn`, a shareable wrapper
  over `stdin` that can be listened to several times in sequence.
* Call `await promptTerminate()` (or `await sharedStdIn.terminate()`) once
  at the end of `main`, otherwise the process keeps running.
* `Shell(stdin: sharedStdIn)` forwards the terminal input to child
  processes (password prompts, `sudo --stdin`).

### Zone aware stdout/stderr (`package:process_run/stdio.dart`)

* `package:process_run/stdio.dart` re-exports `dart:io` but replaces
  `stdout` and `stderr` with zone-aware getters. Import it instead of
  `dart:io` in scripts and tools; outside a zone they are the regular sinks.
* `shellStdioLinesGrouper.runZoned(() async { ... })` groups the output
  produced inside the callback (by `stdout.writeln`, `stderr.writeln` and
  verbose `Shell` runs) so that several concurrent callbacks do not
  interleave their lines: one zone is printed at a time, the others are
  buffered and flushed in the order the zones were started.
* `ShellStdio` is the interface (`out`, `err` sinks); a `Shell` created
  inside the zone with `verbose: true` and no explicit sinks writes to the
  zone sinks automatically.

### Legacy command objects (`package:process_run/cmd_run.dart`)

* `ProcessCmd(executable, arguments, {workingDirectory, environment, runInShell, ...})`,
  `DartCmd(arguments)`, `PubCmd(arguments)`, `PubRunCmd`, `PubGlobalRunCmd`,
  `FlutterCmd(arguments)` and `runCmd(cmd, {verbose, commandVerbose, stdout, stderr, stdin})`
  predate `Shell`. `runCmd` does not throw on a non-zero exit code. Prefer
  `Shell` and `ShellCommand` in new code; keep `DartCmd`/`PubCmd` only for
  existing scripts.
* `ProcessResult` gained `toDebugString()` and `command` (the
  `ShellCommand`) through `package:process_run/shell.dart`, and `Process`
  gained `outLines`/`errLines` (`Stream<String>`) for processes you start
  yourself with `Process.start`.

## Examples

### Check the tools a script needs

```dart
import 'package:process_run/shell.dart';

Future<void> requireTools(List<String> names) async {
  var missing = <String>[];
  for (var name in names) {
    if (await which(name) == null) {
      missing.add(name);
    }
  }
  if (missing.isNotEmpty) {
    throw StateError('Missing executables: ${missing.join(', ')}');
  }
}

Future<void> main() async {
  await requireTools(['git', 'dart']);
  await run('git status');
}
```

### Search in a custom directory only

```dart
import 'package:process_run/shell.dart';

String? findTool(String binDir, String name) => whichSync(
      name,
      environment: {'PATH': binDir},
      includeParentEnvironment: false,
    );

void main() {
  print(findTool('/opt/node/bin', 'node'));
  // Same through an environment object
  var env = ShellEnvironment.empty()..paths.add('/opt/node/bin');
  print(env.whichSync('npm'));
}
```

### Dart and Flutter SDK information

```dart
import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';

Future<void> main() async {
  print('dart: $dartExecutable');
  print('sdk: $dartSdkDirPath');
  print('version: $dartVersion channel: $dartChannel');
  if (dartChannel != dartChannelStable) {
    print('not on stable');
  }
  // Runs `dart --version`
  print('dart bin version: ${await getDartBinVersion()}');

  if (isFlutterSupported) {
    print('flutter: $flutterExecutablePath');
    print('flutter dart: $flutterDartExecutablePath');
    var version = await getFlutterBinVersion();
    var channel = await getFlutterBinChannel();
    print('flutter $version ($channel)');
  }
}
```

### Spawn the same dart VM explicitly

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var shell = Shell();
  // Equivalent to `dart run tool/build.dart` since the SDK bin is first
  // in the shell paths; explicit when the script must not depend on PATH.
  await shell.runExecutableArguments(dartExecutable!, [
    'run',
    'tool/build.dart',
  ]);
}
```

### Version of the current package

```dart
import 'package:process_run/package/package.dart';

Future<void> main() async {
  var version = await getPackageVersion();
  print('building ${version ?? 'unversioned'}');
}
```

### Prompt before a destructive action

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var name = await prompt('Project name');
  if (await promptConfirm('Delete build of $name')) {
    await run('dart run tool/clean.dart ${shellArgument(name)}');
  }
  await promptTerminate();
}
```

### Readable output from concurrent scripts

```dart
import 'package:process_run/shell.dart';
import 'package:process_run/stdio.dart';

Future<void> testPackage(String dir) async {
  stdout.writeln('# $dir');
  await Shell().cd(dir).run('dart test');
  stdout.writeln('# $dir done');
}

Future<void> main() async {
  var stdio = shellStdioLinesGrouper;
  await Future.wait([
    stdio.runZoned(() => testPackage('packages/a')),
    stdio.runZoned(() => testPackage('packages/b')),
  ]);
}
```

### User configuration file location

```dart
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

String get myToolConfigPath => join(userAppDataPath, 'my_tool', 'config.yaml');

void main() {
  print(userHomePath); // /home/me
  print(myToolConfigPath); // /home/me/.config/my_tool/config.yaml
}
```

## Common mistakes

* `whichSync('bin/tool')` or `whichSync('/usr/bin/git')`: only bare names
  are searched; a path always returns `null`. Check the file yourself.
* Forgetting `await promptTerminate()` after using `prompt`,
  `promptConfirm` or `sharedStdIn`: the program hangs at exit.
* Using `dartExecutable!` in a Flutter app: it can be `null` when the
  process is not a dart VM and `dart` is not in the paths.
* Expecting `getFlutterBinVersion()` to refresh after installing flutter in
  the same process: the result (including `null`) is cached.
* Calling `Platform.environment` for child processes instead of
  `platformEnvironment`: the child inherits `DART_VM_OPTIONS`, which can
  break `dart` children started from a debugger.
* Mixing `dart:io` `stdout` with `package:process_run/stdio.dart` inside
  `shellStdioLinesGrouper.runZoned`: only the zone-aware sinks are grouped.
