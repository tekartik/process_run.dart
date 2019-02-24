import 'dart:async';

import 'package:path/path.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:process_run/src/user_config.dart';

Future<String> which(String command,
    {@deprecated Map<String, String> env,
    Map<String, String> environment}) async {
  return whichSync(command,
      // ignore: deprecated_member_use, deprecated_member_use_from_same_package
      env: env,
      environment: environment);
}

/// Find the command according to the [paths] or env variables (`PATH`)
String whichSync(String command,
    {@deprecated Map<String, String> env, Map<String, String> environment}) {
  // only valid for single commands
  if (basename(command) != command) {
    return null;
  }
  return findExecutableSync(
      command,
      getUserPaths(environment ??
          // ignore: deprecated_member_use, deprecated_member_use_from_same_package
          env));
}
