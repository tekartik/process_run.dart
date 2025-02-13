import 'dart:async';

import 'package:path/path.dart';
import 'package:process_run/src/shell_environment.dart';

/// Find the command according to the [paths] or env variables (`PATH`)
Future<String?> which(
  String command, {
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
}) async {
  return whichSync(
    command,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
  );
}

/// Find the command according to the [paths] or env variables (`PATH`)
String? whichSync(
  String command, {
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
}) {
  // only valid for single commands
  if (basename(command) != command) {
    return null;
  }
  // Merge system environment
  var shellEnvironment = ShellEnvironment.full(
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
  );
  return shellEnvironment.whichSync(command);
}
