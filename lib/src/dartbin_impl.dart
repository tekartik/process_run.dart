import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:process_run/src/user_config.dart';

bool _dartExecutableLock = false;

var debugDartExecutableForceWhich = false;

String resolveDartExecutable({Map<String, String> environment}) {
  if (!_dartExecutableLock) {
    _dartExecutableLock = true;
    try {
      return findExecutableSync(
          'dart', getUserPaths(environment ?? userEnvironment));
    } finally {
      _dartExecutableLock = false;
    }
  } else {
    // Null when building initial user config
    return null;
  }
}

String _resolvedDartExecutable;

///
/// Get dart vm either from executable or using the which command
///
String get resolvedDartExecutable => _resolvedDartExecutable ??= () {
      if (debugDartExecutableForceWhich) {
        // Don"t try resolving that only works during debug/test
      } else {
        var executable = Platform.resolvedExecutable;
        if (basenameWithoutExtension(executable) == 'dart') {
          return executable;
        }
      }
      return resolveDartExecutable();
    }();

set resolvedDartExecutable(String dartExecutable) =>
    _resolvedDartExecutable = null;
