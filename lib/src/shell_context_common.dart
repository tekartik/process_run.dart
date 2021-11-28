import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:process_run/src/shell_common.dart';
import 'package:process_run/src/shell_environment_common.dart';

/// abstract shell context
abstract class ShellContext {
  /// Shell environment
  ShellEnvironment get shellEnvironment;

  /// Which command.
  Future<String?> which(String command,
      {ShellEnvironment? environment, bool includeParentEnvironment = true});

  /// Path context.
  p.Context get path;

  /// Default shell encoding (systemEncoding on iOS)
  Encoding get encoding;

  Shell newShell(
      {ShellOptions? options,
      Map<String, String>? environment,
      bool includeParentEnvironment = true});

  ShellEnvironment newShellEnvironment({
    Map<String, String>? environment,
  });
}
