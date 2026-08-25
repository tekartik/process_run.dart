import 'package:process_run/src/shell_command.dart';
import 'package:process_run/src/shell_utils.dart';

/// Maximum number of nested alias expansions.
///
/// Only a safety net, in practice a given alias is only expanded once (see
/// [resolveShellCommandAliases]).
const shellAliasMaxDepth = 16;

/// Resolve the `process_run` aliases of a [command].
///
/// [aliases] are the aliases defined in the user or local environment file
/// (`ds env alias set <name> <command>`).
///
/// Only the executable (i.e. the first word of the command line) is looked up,
/// the alias expansion arguments are prepended to the command arguments. With
/// the alias `qr: my_qr_app --verbose`, `qr file.png` is resolved as
/// `my_qr_app --verbose file.png`.
///
/// Nested aliases are supported (an alias can refer to another alias). Like in
/// bash, a given alias is only expanded once so that self referencing aliases
/// such as `ls: ls --color` don't loop forever.
///
/// The command is returned as is when no alias matches.
ShellCommand resolveShellCommandAliases(
  ShellCommand command,
  Map<String, String> aliases,
) {
  var executable = command.executable;
  var arguments = command.arguments;

  /// Aliases already expanded, to prevent infinite loops.
  var expanded = <String>{};

  while (expanded.length < shellAliasMaxDepth) {
    var alias = aliases[executable];
    if (alias == null) {
      // Not an alias, we're done.
      break;
    }
    if (!expanded.add(executable)) {
      // Already expanded once (self or circular reference), stop here.
      break;
    }
    var parts = shellSplit(alias);
    if (parts.isEmpty) {
      // Empty alias, ignore it.
      break;
    }
    executable = parts.first;
    arguments = [...parts.skip(1), ...arguments];
  }
  return ShellCommand(executable, arguments);
}
