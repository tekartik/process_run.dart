# ds command line and env.yaml reference

## Invocation

```
dart pub global activate process_run   # installs `ds`
ds <command> [arguments]
dart run process_run:shell <command> [arguments]   # same, from a project
```

Global flags: `-h`/`--help`, `-v`/`--verbose`, `--version`.
`env` flags: `-l`/`--local` (default, `.local/ds_env.yaml` in the current
directory) and `-u`/`--user` (`~/.config/tekartik/process_run/env.yaml` or
`%APPDATA%\tekartik\process_run\env.yaml`).

## Command tree

| Command | Effect |
| --- | --- |
| `ds run <command...>` | run one command line with the process_run environment (aliases, paths, vars); several arguments are joined and quoted |
| `ds run --info <command...>` | print the command and the user/local files with their vars, paths and aliases |
| `ds env --info` | print the selected env file content summary |
| `ds env info` | print both env files summary |
| `ds env edit` | create the file if needed and open it (gedit, notepad, TextEdit or vi) |
| `ds env delete [-f]` | delete the selected env file (prompts unless `-f`) |
| `ds env var set NAME value...` | set a variable (value words joined with spaces) |
| `ds env var get NAME...` | print `NAME: value` for the defined names, `not found` otherwise |
| `ds env var dump` | print every variable of the current shell environment, sorted |
| `ds env var delete NAME` | remove the variable from the file |
| `ds env path prepend DIR...` | put the directories first in the file `path:` list |
| `ds env path get DIR...` | print the given directories that are present |
| `ds env path dump` | print every path of the current shell environment |
| `ds env path delete DIR...` | remove the directories from the file |
| `ds env alias set NAME command...` | set an alias |
| `ds env alias get NAME` / `dump` | print aliases |
| `ds env alias delete NAME` | remove the alias |

Examples:

```
ds env var set MY_VAR my_value
ds env alias set hello echo Hello
ds run hello World            # runs `echo Hello World`
ds env path prepend -u C:\app\flutter\stable\flutter\bin
ds run flutter --version
```

## env.yaml format

```yaml
# `path` or `paths`: a list or a single string, `~` is expanded
path:
  - ~/Android/Sdk/platform-tools
  - /opt/tools/bin
# `var` or `vars`: a map (a list of single entry maps is also accepted)
var:
  ANDROID_TOP: ~/Android
  MY_PROJECT_ID: WKDL_456_Q
# `alias` or `aliases`: name to command line
alias:
  qr: /path/to/my_qr_app
  ll: ls -l
```

Resolution order when the environment is built: process environment, then
the user file, then the running dart SDK `bin` directory (and the flutter
`bin` directory when dart comes from flutter) prepended to the paths, then
the local file. Later entries win for vars and aliases; their paths are
prepended.

Environment variables changing the locations:

| Variable | Overrides |
| --- | --- |
| `TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH` | user file path |
| `TEKARTIK_PROCESS_RUN_LOCAL_ENV_FILE_PATH` | local file path, relative to the current directory (default `.local/ds_env.yaml`) |
| `TEKARTIK_PROCESS_RUN_USER_HOME_PATH` | `userHomePath` |
| `TEKARTIK_PROCESS_RUN_USER_APP_DATA_PATH` | `userAppDataPath` |

## Dart helpers (`package:process_run/shell.dart`)

* `userEnvironment`: `Map<String, String>` merged from the process
  environment and both files (a `ShellEnvironment` at runtime).
* `userPaths`: the resulting `List<String>` of paths.
* `userLoadEnvFile(String path)`: add the vars and paths of another YAML file.
* `userLoadEnv({Map<String, String>? vars, List<String>? paths, Map<String, String>? aliases})`:
  add vars and paths programmatically (aliases are currently ignored).
* `shellEnvironment` getter/setter: the environment used by new shells;
  `null` resets to the user config.
* `platformEnvironment`: `Platform.environment` without `DART_VM_OPTIONS`.
* `userHomePath`, `userAppDataPath`: `HOME`/`USERPROFILE` and
  `%APPDATA%` or `~/.config`.
* `userShellAliasEnabled` (bool, default true on Linux/macOS),
  `userShellAliasShellPathOverride` (String?), `userShellAliasShellPath`
  (String?, resolved shell), `userShellAliasSupportedShells`
  (`List<String>`).
* `ShellEnvironment.runZoned(action)`: zone scoped default environment.
* `Shell.shellVarOverride(name, value, {local})`: write a variable to a file
  and return a shell using it.

Internal but importable (`package:process_run/src/user_config.dart`, may
change): `getUserEnvFilePath([environment])`,
`getLocalEnvFilePath([environment])`, `getUserConfig(environment)`,
`getUserPaths(environment)`, `loadFromPath(path)` returning an
`EnvFileConfig` with `paths`, `vars`, `aliases`.
