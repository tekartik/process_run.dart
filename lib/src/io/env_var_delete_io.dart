import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/io/env_io.dart';

class ShellEnvVarDeleteIoHelper extends ShellEnvIoHelper {
  ShellEnvVarDeleteIoHelper({required super.local, required super.verbose});

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

    // Force reload
    shellEnvironment = null;
    if (verbose) {
      stdout.writeln('After: ${jsonEncode(ShellEnvironment().vars)}');
    }
    return ShellEnvironment();
  }
}
