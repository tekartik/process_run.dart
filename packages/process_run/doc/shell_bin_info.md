# Manipulate environment

Binary utility that allow changing from the command line the environment (var, path, alias) used in Shell.

### Setup

```shell
# Add ds utility
pub global activate process_run
```
### Example

```
# Version
ds --version

# Run using the shell environment (alias, path and var=
ds run echo Hello World

# Set a var
ds env var set MY_VAR my_value

# Set an alias
ds env alias set ll ls -l

# Add a path (prepend only)
ds env path prepend dummy/relative/folder

# Windows example to add flutter bin in the path
# The following command will work even if flutter is not globally in your PATH
# env variable (from your IDE for example)
# await run('flutter --version');
ds env path prepend -u C:\app\flutter\stable\flutter\bin
```

### Running an alias

`ds run <command> [<arguments>]` resolves `<command>` using the aliases defined
in the [user config](user_config.md). The extra arguments are appended:

```shell
# Define the alias
ds env alias set hello echo Hello

# Runs `echo Hello World`
ds run hello World
```

An alias can refer to another alias. Like in bash, a given alias is only
expanded once so `ds env alias set ls ls --color` does not loop.

Use `ds run --info <command>` to dump the environment (vars, paths and aliases)
used to resolve a command.

#### User shell aliases (linux/macOS only)

When a command is neither a `process_run` alias nor an existing binary, the
user shell aliases are tried as a last resort, so that:

```shell
# With `alias ll='ls -alF'` defined in `~/.bashrc`
ds run ll
```

works. The shell is the one from the `SHELL` environment variable (i.e. the
user shell), `bash` when it is not set. `bash` (linux default), `zsh` (macOS
default), `sh`, `dash`, `ash` and the `ksh` variants are supported
(`userShellAliasSupportedShells`): they are
run interactively (`<shell> -ic 'alias "$1"' <shell> <name>`) so that they read
the user configuration where the aliases are defined (`~/.bashrc`, `~/.zshrc`,
the file pointed by `$ENV` for `dash`...).

An unsupported shell such as `fish` simply means no fallback: we never guess
using another shell as the aliases would be defined somewhere else. Use
`userShellAliasShellPathOverride` to force a shell.

This is a best effort feature (spawning an interactive shell is slow, the
result is cached and it only happens when the command was going to fail
anyway), it is only supported on Linux and macOS for now and can be turned off
from dart using `userShellAliasEnabled = false`.
