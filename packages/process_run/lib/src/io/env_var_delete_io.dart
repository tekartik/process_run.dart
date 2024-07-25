import 'dart:convert';

import 'package:process_run/shell.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/io/env_io.dart';
import 'package:process_run/src/io/io.dart';

/// Helper to delete environment variables
class ShellEnvVarDeleteIoHelper extends ShellEnvIoHelper {
  /// Helper to delete environment variables
  ShellEnvVarDeleteIoHelper(
      {required super.shell, required super.local, required super.verbose});

  /// delete multiple environment variables
  Future<ShellEnvironment> deleteMulti(List<String> keys) async {
    var fileContent = await envFileReadOrCreate();
    var modified = false;
    for (var name in keys) {
      modified = fileContent.deleteVar(name) || modified;
    }
    if (modified) {
      if (verbose) {
        stdout.writeln('writing file');
      }
      await fileContent.write();
    }

    if (verbose) {
      stdout.writeln('After: ${jsonEncode(ShellEnvironment().vars)}');
    }

    // Convenient fix, although it could be wrong...
    var newShellEnvironment = shell.context.newShellEnvironment(
        environment: ShellEnvironment(environment: shell.options.environment));

    newShellEnvironment.vars.removeWhere((name, _) => keys.contains(name));

    return ShellEnvironment();
  }
}
