import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:yaml/yaml.dart';

import 'common/import.dart';

class UserConfig {
  Map<String, String> vars;
  List<String> paths;

  @override
  String toString() => '${vars?.length} vars ${paths?.length} paths';
}

UserConfig _userConfig;
UserConfig get userConfig =>
    _userConfig ??
    () {
      return getUserConfig(null);
    }();

/// Dev only
@protected
set userConfig(UserConfig userConfig) => _userConfig = userConfig;

///
/// Get the list of user paths used to resolve binaries location.
///
/// It includes items from the PATH environment variable.
///
/// It can be overriden to include user defined paths loaded from
/// ~/.config/tekartik/process_run/env.yam
///
/// See [https://github.com/tekartik/process_run.dart/blob/master/doc/user_config.md]
/// in the documentation for more information.
///
List<String> get userPaths => userConfig.paths;

/// Get the user environment
///
/// It includes current system user environment.
///
/// It can be overriden to include user defined variables loaded from
/// ~/.config/tekartik/process_run/env.yam
///
/// [userEnvironment] must be explicitly used as it could contain sensitive
/// information.
///
Map<String, String> get userEnvironment => userConfig.vars;

// Test only
@protected
void resetUserConfig() {
  _userConfig = null;
}

/// Get config map
UserConfig getUserConfig(Map<String, String> environment) {
  var paths = <String>[];
  var userEnvironment = <String, String>{};

  environment ??= platformEnvironment;

  // Include shell environment
  userEnvironment.addAll(environment);

  try {
    // Look for any config file in ~/tekartik/process_run/env.yaml
    var userConfig =
        loadYaml(File(getUserEnvFilePath(environment)).readAsStringSync());
    if (userConfig is Map) {
      // Handle added path
      // can be
      //
      // path:~/bin
      //
      // or
      //
      // path:
      //   - ~/bin
      //   - ~/Android/Sdk/tools/bin
      //

      // Add current dart path
      var path = userConfig['path'];
      if (path is List) {
        paths.addAll(path.map((path) => expandPath(path.toString())));
      } else if (path is String) {
        paths.add(expandPath(path.toString()));
      }

      // Handle variable like
      //
      // var:
      //   ANDROID_TOP: /home/user/Android
      //   FIREBASE_TOP: /home/user/.firebase
      void _add(key, value) {
        // devPrint('$key: $value');
        if (key != null) {
          userEnvironment[key?.toString()] = value?.toString() ?? '';
        }
      }

      var vars = userConfig['var'];
      if (vars is List) {
        vars.forEach((item) {
          if (item is Map) {
            if (item.isNotEmpty) {
              var entry = item.entries.first;
              var key = entry.key;
              var value = entry.value;
              _add(key, value);
            }
          } else {
            // devPrint(item.runtimeType);
          }
          // devPrint(item);
        });
      }
      if (vars is Map) {
        vars.forEach((key, value) {
          _add(key, value);
        });
      }
    }
  } catch (_) {}

  // Add dart path so that dart commands always work!
  paths.add(dartSdkBinDirPath);

  // Add from environment
  paths.addAll(getEnvironmentPaths(environment));

  return UserConfig()
    ..paths = paths
    ..vars = userEnvironment;
}

// Fix environment with global settings and current dart sdk
List<String> getUserPaths(Map<String, String> environment) =>
    getUserConfig(environment).paths;

/// Get the user env file path
String getUserEnvFilePath([Map<String, String> environment]) {
  return (environment ?? platformEnvironment)[userEnvFilePathEnvKey] ??
      join(userAppDataPath, 'tekartik', 'process_run', 'env.yaml');
}
