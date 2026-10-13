import 'dart:convert';

import 'package:process_run/shell.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/io/env_io.dart';
import 'package:process_run/src/io/io.dart';

/// Helper to set environment variables
class ShellEnvVarSetIoHelper extends ShellEnvIoHelper {
  /// Local should be true by default
  ShellEnvVarSetIoHelper({
    required super.shell,
    required super.local,
    super.verbose = true,
  });

  /// Set a single environment variable
  Future<ShellEnvironment> setValue(String name, String? value) async {
    if (verbose) {
      stdout.writeln('file $label: $envFilePath');
      stdout.writeln('before: ${jsonEncode(ShellEnvironment().vars)}');
    }

    if (local && name == localEnvFilePathEnvKey) {
      // Not written, it would have no effect
      stderr.writeln('$name cannot be set in local file');
    } else {
      var fileContent = await envFileReadOrCreate();
      bool modified;
      if (value != null) {
        modified = fileContent.addVar(name, value);
      } else {
        modified = fileContent.deleteVar(name);
      }
      if (modified) {
        if (verbose) {
          stdout.writeln('writing file');
        }
        await fileContent.write();
      }
    }
    // reload
    var newShellEnvironment = shell.context.newShellEnvironment(
      environment: ShellEnvironment(environment: shell.options.environment),
    );
    if (value == null) {
      newShellEnvironment.vars.remove(name);
    } else {
      newShellEnvironment.vars[name] = value;
    }
    if (verbose) {
      stdout.writeln('After: ${jsonEncode(newShellEnvironment.vars)}');
    }
    return newShellEnvironment;
  }
}
