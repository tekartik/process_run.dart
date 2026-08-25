/// User shell alias support.
///
/// **Linux and macOS only for now** (see [userShellAliasEnabled]).
///
/// `Shell` resolves the `process_run` aliases (the ones defined in the user or
/// local `env.yaml` file, see `ds env alias`) by itself. This file adds a *last
/// resort* fallback: when an executable is neither a `process_run` alias nor
/// found in the paths, we ask the user shell whether it knows an alias with
/// that name, so that `ds run ll` can work when the user has
/// `alias ll='ls -alF'` in its shell configuration.
///
/// How it works: `<shell> -ic 'alias "$1"' <shell> <name>` is run, [shell]
/// being the user shell (`SHELL` environment variable, see
/// [userShellAliasShellPath]). `-i` makes the shell interactive so that it
/// reads the user configuration where aliases live (`~/.bashrc`, `~/.zshrc`,
/// `$ENV`...): a non interactive shell does not read it and does not even
/// expand aliases. The alias name is passed as an argument (never interpolated
/// in the script) so that it cannot be injected. The shell prints the
/// definition on stdout, in one of the 2 forms handled by
/// [parseUserShellAliasDefinition]:
///
/// ```
/// alias ll='ls -alF'
/// ll='ls -alF'
/// ```
///
/// Supported shells are listed in [userShellAliasSupportedShells]: they all
/// support `-i -c` with positional arguments and have an `alias <name>`
/// builtin. That covers the linux (`bash`) and macOS (`zsh`) defaults. Note
/// that `--` is *not* used to end the options as `dash` does not support it
/// (names starting with `-` are simply rejected instead).
///
/// Caveats, and why this is only a fallback:
/// - it spawns an interactive shell, which reads the whole user configuration:
///   it is slow and could have side effects. It is only done when the command
///   could not be resolved otherwise (so when the command was going to fail
///   anyway) and the result is cached for the process lifetime.
/// - the configuration files often write on stdout, so every output line is
///   tried and only the one matching the alias name is used. For the same
///   reason the exit code is ignored.
/// - `fish` is not supported (its aliases are functions and its `alias`
///   builtin behaves differently). An unsupported shell simply means no
///   fallback, we never guess using another shell as the aliases of the user
///   would be defined somewhere else.
/// - a `sh`/`dash` user usually has no alias to find as an interactive `dash`
///   only reads the file pointed by the `ENV` environment variable.
library;

import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process_run/src/io/io.dart';
import 'package:process_run/src/shell_command.dart';
import 'package:process_run/src/shell_utils.dart';

/// Whether the user shell alias fallback is used.
///
/// Only enabled on Linux and macOS for now. Can be set to `false` to turn the
/// feature off (or to `true` on another platform at your own risk).
var userShellAliasEnabled = Platform.isLinux || Platform.isMacOS;

/// Shells the aliases can be read from.
///
/// They all support `<shell> -i -c '<script>' <name0> <arg>` and have an
/// `alias <name>` builtin. Only the base name of the shell is checked.
const userShellAliasSupportedShells = <String>[
  'bash',
  'zsh',
  'sh',
  'dash',
  'ash',
  'ksh',
  'ksh93',
  'mksh',
  'pdksh',
];

/// Explicit shell to use for the alias lookup.
///
/// `null` (the default) means use the `SHELL` environment variable, see
/// [userShellAliasShellPath].
String? userShellAliasShellPathOverride;

/// The shell used for the alias lookup, `null` when unsupported.
///
/// It is [userShellAliasShellPathOverride] when set, the `SHELL` environment
/// variable (i.e. the user shell) otherwise.
///
/// `bash` is used when `SHELL` is not set (it happens when running from an IDE
/// or a service), `null` is returned when the user shell is not one of
/// [userShellAliasSupportedShells] (`fish`...). Note that the parent process
/// is not used to detect the shell: a compiled script is often run through a
/// `sh` wrapper, which would always answer `sh`.
String? get userShellAliasShellPath {
  var path = userShellAliasShellPathOverride ?? platformEnvironment['SHELL'];
  if (path == null || path.isEmpty) {
    // No `SHELL` information, don't assume bash (the linux default, and available
    // on macOS too).
    return null;
  }
  if (!userShellAliasSupportedShells.contains(basename(path))) {
    return null;
  }
  return path;
}

/// Overrides the user shell alias lookup (testing only).
///
/// When set, it is used instead of spawning a shell, on any platform.
@visibleForTesting
String? Function(String name)? debugUserShellAliasResolver;

/// Cache of the resolved aliases (`null` value means 'no such alias').
final _userShellAliasCache = <String, String?>{};

/// Clear the alias cache (testing only).
@visibleForTesting
void resetUserShellAliasCache() => _userShellAliasCache.clear();

/// The shell command line used for the lookup.
///
/// `$1` is the alias name, passed as an argument (the shell name being `$0`).
const _shellAliasScript = 'alias "\$1"';

/// Parse an `alias` definition as printed by bash (`alias ll='ls -alF'`) or
/// zsh/dash (`ll='ls -alF'`).
///
/// The optional [name] is the expected alias name, `null` is returned when the
/// line defines another alias (or is not an alias definition at all, the shell
/// configuration files do write on stdout).
///
/// Returns the alias command line, unquoted: the value is single quoted by the
/// shell, an embedded single quote being escaped as `'\''` (bash/zsh) or
/// `'"'"'` (dash/ash).
String? parseUserShellAliasDefinition(String line, {String? name}) {
  var text = line.trim();
  const prefix = 'alias ';
  if (text.startsWith(prefix)) {
    text = text.substring(prefix.length).trimLeft();
  }
  var index = text.indexOf('=');
  if (index <= 0) {
    return null;
  }
  if (name != null && text.substring(0, index) != name) {
    return null;
  }
  var value = text.substring(index + 1).trim();
  try {
    // Let the shell word splitter handle the quoting, whichever the shell
    // escaping style is. A properly quoted value is a single word.
    var parts = shellSplit(value);
    if (parts.length == 1) {
      value = parts.first;
    }
  } catch (_) {
    // Unbalanced quotes, keep the raw value.
  }
  return value.isEmpty ? null : value;
}

/// Ask the user [shell] for the definition of the [name] alias, `null` if none.
///
/// Not cached, prefer [findUserShellAliasSync]. [shell] defaults to
/// [userShellAliasShellPath]. [environment] can be used to override the
/// environment of the spawned shell (`HOME` typically, for testing).
@visibleForTesting
String? userShellFindAliasSync(
  String name, {
  String? shell,
  Map<String, String>? environment,
}) {
  shell ??= userShellAliasShellPath;
  if (shell == null) {
    // Unsupported shell.
    return null;
  }
  // A name starting with `-` would be handled as an option by the `alias`
  // builtin (and `--` cannot be used as dash does not support it). No such
  // alias exists in practice.
  if (name.isEmpty || name.startsWith('-')) {
    return null;
  }
  try {
    var result = Process.runSync(
      shell,
      ['-ic', _shellAliasScript, basename(shell), name],
      environment: environment,
      stdoutEncoding: systemEncoding,
    );
    // The exit code is not reliable (an interactive shell can fail on
    // something else), only the output matters.
    for (var line in LineSplitter.split(result.stdout.toString())) {
      var alias = parseUserShellAliasDefinition(line, name: name);
      if (alias != null) {
        return alias;
      }
    }
  } catch (_) {
    // The shell might not be available, ignore.
  }
  return null;
}

/// Find the user shell alias [name], `null` if none.
///
/// Linux/macOS only unless [debugUserShellAliasResolver] is set. The result is
/// cached for the lifetime of the process.
String? findUserShellAliasSync(String name) {
  var resolver = debugUserShellAliasResolver;
  if (resolver != null) {
    return resolver(name);
  }
  if (!userShellAliasEnabled) {
    return null;
  }
  if (_userShellAliasCache.containsKey(name)) {
    return _userShellAliasCache[name];
  }
  return _userShellAliasCache[name] = userShellFindAliasSync(name);
}

/// Resolve a [command] executable using the user shell aliases.
///
/// Returns `null` when the executable is not a known user shell alias (or when
/// the feature is not supported/enabled).
///
/// Only one level of expansion is done (unlike the `process_run` aliases, see
/// `resolveShellCommandAliases`), which covers the usual
/// `alias ll='ls -alF'` case.
ShellCommand? resolveShellCommandUserShellAlias(ShellCommand command) {
  if (debugUserShellAliasResolver == null && !userShellAliasEnabled) {
    return null;
  }
  var executable = command.executable;
  // Only a plain name can be an alias, not a path.
  if (executable.isEmpty || basename(executable) != executable) {
    return null;
  }
  var alias = findUserShellAliasSync(executable);
  if (alias == null) {
    return null;
  }
  List<String> parts;
  try {
    parts = shellSplit(alias);
  } catch (_) {
    return null;
  }
  if (parts.isEmpty) {
    return null;
  }
  return ShellCommand(parts.first, [...parts.skip(1), ...command.arguments]);
}
