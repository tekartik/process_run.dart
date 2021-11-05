import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';

/// abstract shell context
abstract class ShellContext {
  /// Shell environment
  ShellEnvironment get shellEnvironment;

  /// Which command.
  Future<String?> which(String command);

  /// Path context.
  p.Context get path;

  /// Default shell encoding (systemEncoding on iOS)
  Encoding get encoding;
}
