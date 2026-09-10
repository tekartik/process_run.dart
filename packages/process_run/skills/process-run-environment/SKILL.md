---
name: process-run-environment
description: >-
  Use when configuring the environment of commands run with
  package:process_run: ShellEnvironment (vars, paths, aliases, merge,
  prepend, whichSync), Shell(environment:), includeParentEnvironment, the
  global shellEnvironment and platformEnvironment, userEnvironment/userPaths,
  the user and local env.yaml files (~/.config/tekartik/process_run/env.yaml,
  .local/ds_env.yaml), userLoadEnv/userLoadEnvFile, alias resolution and the
  user shell alias fallback (userShellAliasEnabled), ShellEnvironment.runZoned,
  shellVarOverride, and the ds command line (dart run process_run:shell env
  var/path/alias set|get|dump|delete, ds run, ds env edit).
---

# process_run environment: variables, paths and aliases

`package:process_run/shell.dart` gives every `Shell` a `ShellEnvironment`:
the environment variables of the child processes, the list of directories
used to resolve executables (`PATH`) and command aliases. The default one is
the process environment plus what the user configured in `env.yaml` files,
so a script finds `flutter` or `firebase` even when the IDE did not export
the right `PATH`.

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var env = ShellEnvironment()
    ..vars['CI'] = 'true'
    ..paths.prepend('/opt/flutter/bin')
    ..aliases['ll'] = 'ls -l';
  var shell = Shell(environment: env);
  await shell.run('flutter --version');
  await shell.run('ll');
}
```

## Guidelines

### ShellEnvironment

* `ShellEnvironment()` copies the current shell environment (process
  variables, user config vars, paths and aliases, and the running dart SDK
  `bin` directory prepended to the paths). `ShellEnvironment.empty()` starts
  from nothing. `ShellEnvironment(environment: map)` copies a plain map
  (its `PATH` becomes `paths`); passing a `ShellEnvironment` also copies its
  aliases.
* It is a `Map<String, String>` (the variables including `PATH`) with three
  views:
  `vars` (a `Map<String, String>` of every variable except `PATH`),
  `paths` (a `List<String>` view of `PATH`: `prepend`, `add`, `addAll`,
  `insert`, `remove`; duplicates are dropped) and
  `aliases` (a `Map<String, String>` of name to command line).
* `env.merge(other)`: `other` wins for vars and aliases, its paths are
  prepended. `env.whichSync(name)` / `await env.which(name)` resolve an
  executable in that environment only. `toJson()` / `ShellEnvironment.fromJson`
  give `{'paths': [...], 'vars': {...}, 'aliases': {...}}`.
* Treat an environment as immutable once given to a `Shell`: the shell copies
  it into its options. Build a new one (or `ShellEnvironment(environment: old)`)
  for changes.

### Applying it to a shell

* `Shell(environment: env)` with the default `includeParentEnvironment: true`
  merges `env` on top of the full current environment (vars override, paths
  prepended, aliases added). Pass a small `ShellEnvironment` or a plain
  `Map<String, String>` with only the additions.
* `Shell(environment: env, includeParentEnvironment: false)` gives the child
  exactly `env`: you then own `PATH`, `HOME`, `TEMP` etc. Use it for
  reproducible builds or tests, and put the needed paths in `env.paths`.
* `shell.options.environment` is the effective `ShellEnvironment` of a shell.
  `shell.cloneWithOptions(shell.options.clone(shellEnvironment: env))`
  derives a shell with another environment; `cd`/`pushd` keep it.
* The global `shellEnvironment` getter returns the environment used by every
  new `Shell()`/`run()`; assigning it (`shellEnvironment = env`) changes all
  subsequent shells in the process and `shellEnvironment = null` restores the
  user config. Prefer per-shell environments; use the global only in a CLI
  entry point.
* `platformEnvironment` is `Platform.environment` without `DART_VM_OPTIONS`
  (replaced by `TEKARTIK_DART_VM_OPTIONS` when set): use it instead of
  `Platform.environment` when a Dart child must not inherit debugger options.
* `await env.runZoned(() async { ... })` makes `env` the default environment
  inside the callback (for `Shell()`, `run()`, `ShellEnvironment()`, `which`)
  without touching the global. Zones are isolated from each other, so
  concurrent zones can use different values.

### Executable and alias resolution

* The first word of a command line is looked up, in order: the shell
  environment aliases (nested aliases allowed, each expanded once, alias
  arguments prepended: with `qr: my_app --verbose`, `qr file.png` runs
  `my_app --verbose file.png`), then the executable in `paths`.
* Last resort on Linux/macOS: when nothing is found, the user shell
  (`$SHELL`: bash, zsh, sh, dash, ash, ksh; not fish) is asked for an alias
  of that name (`alias ll='ls -alF'` in `~/.bashrc`/`~/.zshrc`). Turn it off
  with `userShellAliasEnabled = false`, force a shell with
  `userShellAliasShellPathOverride = '/bin/zsh'`; `userShellAliasShellPath`
  tells which shell will be used, `userShellAliasSupportedShells` lists the
  supported names. It spawns an interactive shell (slow, cached per
  process) and only triggers on commands that would fail anyway.
* Aliases are the portable way to name a tool whose location differs per
  machine (`env.aliases['echo'] = compiledEchoPath` in tests, `ds` to
  `dart run bin/shell.dart` in development).

### User configuration files (`env.yaml`)

* User file: `~/.config/tekartik/process_run/env.yaml` on Linux/macOS,
  `%APPDATA%\tekartik\process_run\env.yaml` on Windows. Local file:
  `.local/ds_env.yaml` in the current directory, applied after the user file
  (it wins). Both are read once per process when the first shell environment
  is built.
* YAML keys: `path` (or `paths`, a list or a single string, `~` expanded),
  `var` (or `vars`, a map) and `alias` (or `aliases`, a map). The paths are
  prepended to `PATH`, the vars override the process ones.
* Override the locations with the environment variables
  `TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH` (absolute user file),
  `TEKARTIK_PROCESS_RUN_LOCAL_ENV_FILE_PATH` (relative local file),
  `TEKARTIK_PROCESS_RUN_USER_HOME_PATH` and
  `TEKARTIK_PROCESS_RUN_USER_APP_DATA_PATH`. Set them in tests to keep the
  developer files untouched.
* `userEnvironment` (a `Map<String, String>`) and `userPaths`
  (`List<String>`) expose the merged result; `userLoadEnvFile(path)` and
  `userLoadEnv(vars: {...}, paths: [...])` add vars and paths to it for the
  whole process (aliases passed to `userLoadEnv` are not applied). Prefer
  a `ShellEnvironment` per shell.
* `await shell.shellVarOverride('NAME', 'value')` writes the variable in the
  local file (`local: false` for the user file), `null` deletes it, and
  returns a new `Shell` whose environment has the change.
* Keep secrets in the user file `var:` section rather than in code; they are
  in `userEnvironment` and in every `ShellEnvironment()`.

### The `ds` command line

* Install with `dart pub global activate process_run` (executable `ds`), or
  run it in a project with `dart run process_run:shell <args>`.
* `ds run <command...>`: run one command line with the process_run
  environment (aliases, paths, vars). `ds run --info <command>` dumps the
  files, vars, paths and aliases used.
* `ds env var set NAME value words` / `get NAME` / `dump` / `delete NAME`;
  `ds env path prepend <dir...>` / `get <dir...>` / `dump` / `delete <dir...>`;
  `ds env alias set NAME command words` / `get NAME` / `dump` /
  `delete NAME`. Values can span several arguments, they are joined with
  spaces.
* Every `env` command edits the local file by default (`-l`, `--local`);
  add `-u` / `--user` for the user file. `ds env edit` opens the file in an
  editor, `ds env info` and `ds env --info` print the files, `ds env delete`
  (`-f` to skip the prompt) removes the file.
* In a Dart script that must call `ds`, alias it:
  `ShellEnvironment()..aliases['ds'] = 'dart run process_run:shell'`.

## Examples

### Add a tool directory and a variable for one shell

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var env = ShellEnvironment()
    ..paths.prepend('/opt/android/platform-tools')
    ..vars['ANDROID_SERIAL'] = 'emulator-5554';
  var shell = Shell(environment: env, verbose: false);
  var devices = await shell.run('adb devices');
  print(devices.outText);
}
```

### Minimal, fully controlled environment

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var env = ShellEnvironment.empty()
    ..paths.addAll(['/usr/bin', '/bin'])
    ..vars['HOME'] = '/tmp/build-home'
    ..vars['LANG'] = 'C';
  var shell = Shell(environment: env, includeParentEnvironment: false);
  await shell.run('env');
}
```

### Aliases, including nested ones

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var env = ShellEnvironment()
    ..aliases['fvm_flutter'] = 'fvm flutter'
    ..aliases['fbuild'] = 'fvm_flutter build';
  var shell = Shell(environment: env);
  // Runs `fvm flutter build apk --release`.
  await shell.run('fbuild apk --release');
}
```

### Check a tool from a given environment

```dart
import 'package:process_run/shell.dart';

bool hasFirebaseCli(ShellEnvironment env) => env.whichSync('firebase') != null;

Future<void> main() async {
  var env = ShellEnvironment()..paths.prepend('/home/me/.firebase/tools/bin');
  if (!hasFirebaseCli(env)) {
    print('firebase not found in ${env.paths}');
    return;
  }
  await Shell(environment: env).run('firebase --version');
}
```

### Scoped default environment with runZoned

```dart
import 'package:process_run/shell.dart';

Future<void> buildFlavor(String flavor) => (ShellEnvironment()
      ..vars['FLAVOR'] = flavor)
    .runZoned(() async {
  // Every Shell()/run() created here sees FLAVOR=flavor.
  await run('dart run tool/build.dart');
});

Future<void> main() async {
  await Future.wait([buildFlavor('dev'), buildFlavor('prod')]);
}
```

### Persist a variable in the local env.yaml

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var shell = Shell(verbose: false);
  // Written to .local/ds_env.yaml, picked up by every future `ds run`
  // and `Shell()` in this directory.
  shell = await shell.shellVarOverride('MY_PROJECT_ID', 'proj-123');
  print(shell.options.environment.vars['MY_PROJECT_ID']); // proj-123
  // Delete it.
  shell = await shell.shellVarOverride('MY_PROJECT_ID', null);
}
```

### Sample `~/.config/tekartik/process_run/env.yaml`

```yaml
path:
  - ~/.android/bin
  - ~/.firebase/tools/bin
  - /home/user/Apps/bin
var:
  ANDROID_TOP: ~/.android
  MY_PROJECT_ID: WKDL_456_Q
alias:
  qr: /path/to/my_qr_app
  hello: echo Hello
```

### Redirect the config files in tests

```dart
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void main() {
  test('isolated env files', () async {
    var env = ShellEnvironment()
      ..vars['TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH'] =
          '.dart_tool/test/user_env.yaml'
      ..vars['TEKARTIK_PROCESS_RUN_LOCAL_ENV_FILE_PATH'] =
          '.dart_tool/test/local_env.yaml'
      ..aliases['ds'] = 'dart run process_run:shell';
    var shell = Shell(environment: env, verbose: false);
    await shell.run('ds env var set TEST_VAR 1');
    var out = (await shell.run('ds env var get TEST_VAR')).outText;
    expect(out, contains('TEST_VAR: 1'));
  });
}
```

## Common mistakes

* `env.vars['PATH'] = ...`: ignored, `PATH` is only editable through
  `env.paths`.
* Mutating a `ShellEnvironment` after creating the `Shell` and expecting the
  shell to see it: create a new shell (`cloneWithOptions`) instead.
* `includeParentEnvironment: false` with an environment that has no `paths`:
  no executable can be resolved and the child has no `PATH`.
* Assigning the global `shellEnvironment` in a library: it leaks into every
  shell of the application. Use `Shell(environment:)` or `runZoned`.
* Expecting `alias` entries added with `userLoadEnv(aliases:)` to work: only
  `vars` and `paths` are applied; use `ShellEnvironment.aliases` or the
  `env.yaml` `alias:` section.
* Expecting `ds env var set` to affect the current shell object: it edits
  the file; use `shellVarOverride` or create a new `Shell` afterwards.
* Running `ds` on Windows/Linux without `dart pub global activate
  process_run` or the `dart run process_run:shell` prefix.

## More

See [references/ds-cli.md](references/ds-cli.md) for the full `ds` command
tree, the `env.yaml` format details and the lower level helpers
(`getUserEnvFilePath`, `getLocalEnvFilePath`, `userConfig`).
