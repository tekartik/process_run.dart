import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/io/env_io.dart';

import '../platform/platform.dart';

class ShellEnvVarSetIoHelper extends ShellEnvIoHelper {
  /// Local should be true by default
  ShellEnvVarSetIoHelper({required super.local, super.verbose = true});

  Future<ShellEnvironment> setValue(String name, String? value) async {
    if (verbose) {
      stdout.writeln('file $label: $envFilePath');
      stdout.writeln('before: ${jsonEncode(ShellEnvironment().vars)}');
    }

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
    if (local && name == localEnvFilePathEnvKey) {
      stderr.writeln('$name cannot be set in local file');
    }
    // Force reload
    var newShellEnvironment = shellContext.newShellEnvironment(
        environment: Map<String, String>.from(shellEnvironment));
    if (value == null) {
      newShellEnvironment.vars.remove(name);
    } else {
      newShellEnvironment.vars[name] = value;
    }
    if (verbose) {
      stdout.writeln('After: ${jsonEncode(ShellEnvironment().vars)}');
    }
    return newShellEnvironment;
  }
}
