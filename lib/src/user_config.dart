import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/script_filename.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:yaml/yaml.dart';

import 'common/import.dart';

class UserConfig {
  /// never null
  final Map<String, String> vars;

  /// never null
  final List<String> paths;

  UserConfig({Map<String, String> vars, List<String> paths})
      : vars = vars ?? <String, String>{},
        paths = paths ?? <String>[];

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

class EnvFileConfig {
  final String fileContent;

  // hopefully a map
  final dynamic yaml;
  final List<String> paths;
  final Map<String, String> vars;

  EnvFileConfig(this.fileContent, this.yaml, this.paths, this.vars);

  Map<String, dynamic> toDebugMap() =>
      <String, dynamic>{'paths': paths, 'vars': vars};

  @override
  String toString() => toDebugMap().toString();
}

/// Never null, all members can be null
EnvFileConfig loadFromMap(Map<dynamic, dynamic> map) {
  var paths = <String>[];
  var fileVars = <String, String>{};

  try {
    // devPrint('yaml: $yaml');
    if (map is Map) {
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
      var path = map['path'] ?? map['paths'];
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
      void _add(String key, String value) {
        // devPrint('$key: $value');
        if (key != null) {
          fileVars[key] = value;
        }
      }

      var vars = map['var'] ?? map['vars'];
      if (vars is List) {
        vars.forEach((item) {
          if (item is Map) {
            if (item.isNotEmpty) {
              var entry = item.entries.first;
              var key = entry.key?.toString();
              var value = entry.value?.toString();
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
          _add(key?.toString(), value?.toString());
        });
      }
    }
  } catch (e) {
    stderr.writeln('error reading yaml $e');
  }
  return EnvFileConfig(null, null, paths, fileVars);
}

/// Never null, all members can be null
EnvFileConfig loadFromPath(String path) {
  dynamic yaml;
  String fileContent;
  Map<String, String> vars;
  List<String> paths;
  try {
    // Look for any config file in ~/tekartik/process_run/env.yaml
    try {
      fileContent = File(path).readAsStringSync();
    } catch (e) {
      if (verbose) {
        stderr.writeln('error reading env file $path $e');
      }
    }
    if (fileContent != null) {
      yaml = loadYaml(fileContent);
      // devPrint('yaml: $yaml');
      if (yaml is Map) {
        var config = loadFromMap(yaml);
        vars = config.vars;
        paths = config.paths;
      }
    }
  } catch (e) {
    stderr.writeln('error reading yaml $e');
  }
  return EnvFileConfig(fileContent, yaml, paths, vars);
}

/// Update userPaths and userEnvironment
void userLoadEnvFile(String path) {
  userLoadEnvFileConfig(loadFromPath(path));
}

// private
void userLoadConfigMap(Map map) {
  userLoadEnvFileConfig(loadFromMap(map));
}

/// Only specify the vars to override and the paths to add
void userLoadEnv({Map<String, String> vars, List<String> paths}) {
  userLoadEnvFileConfig(EnvFileConfig(null, null, paths, vars));
}

// private
void userLoadEnvFileConfig(EnvFileConfig envFileConfig) {
  var config = userConfig;
  var paths = List<String>.from(config.paths);
  var vars = Map<String, String>.from(config.vars);
  var added = envFileConfig;
  // devPrint('adding config: $config');
  if (added.paths != null) {
    if (const ListEquality().equals(
        paths.sublist(0, min(added.paths.length, paths.length)), added.paths)) {
      // don't add if already in same order at the beginning
    } else {
      paths.insertAll(0, added.paths);
    }
  }
  added.vars?.forEach((key, value) {
    vars[key] = value ?? '';
  });
  // Set env PATH from path
  vars[envPathKey] = paths?.join(envPathSeparator);
  userConfig = UserConfig(vars: vars, paths: paths);
}

/// Returns the matching flutter ancestor if any
String getFlutterAncestorPath(String dartSdkBinDirPath) {
  try {
    var parent = dartSdkBinDirPath;
    if (basename(parent) == 'bin') {
      parent = dirname(parent);
      if (basename(parent) == 'dart-sdk') {
        parent = dirname(parent);
        if (basename(parent) == 'cache') {
          parent = dirname(parent);
          if (basename(parent) == 'bin') {
            return parent;
          }
        }
      }
    }
  } catch (_) {}

  // Second test, check if flutter is at path in this case
  // dart sdk comes from flutter dart path
  try {
    if (File(join(dartSdkBinDirPath, getBashOrBatExecutableFilename('flutter')))
        .existsSync()) {
      return dartSdkBinDirPath;
    }
  } catch (_) {}
  return null;
}

/// Get config map
UserConfig getUserConfig(Map<String, String> environment) {
  var paths = <String>[];
  var vars = <String, String>{};

  environment ??= platformEnvironment;

  // Include shell environment
  vars.addAll(environment);

  void addConfig(String path) {
    var config = loadFromPath(path);
    // devPrint('adding config: $config');
    if (config.paths != null) {
      paths.addAll(config.paths);
    }
    config.vars?.forEach((key, value) {
      vars[key] = value ?? '';
    });
  }

  // Add user config
  addConfig(getUserEnvFilePath(environment));
  // Add local config
  addConfig(getLocalEnvFilePath());

  if (dartExecutable != null) {
    var dartBinPath = dartSdkBinDirPath;

    // Add flutter path if path matches:
    // /flutter/bin/cache/dart-sdk/bin
    var flutterBinPath = getFlutterAncestorPath(dartBinPath);
    if (flutterBinPath != null) {
      paths.add(flutterBinPath);
    }
    // Add dart path so that dart commands always work!
    paths.add(dartBinPath);
  }

  // Add from environment
  paths.addAll(getEnvironmentPaths(environment));

  // Set env PATH from path
  vars[envPathKey] = paths?.join(envPathSeparator);

  return UserConfig(paths: paths, vars: vars);
}

// Fix environment with global settings and current dart sdk
List<String> getUserPaths(Map<String, String> environment) =>
    getUserConfig(environment).paths;

/// Get the user env file path
String getUserEnvFilePath([Map<String, String> environment]) {
  return (environment ?? platformEnvironment)[userEnvFilePathEnvKey] ??
      (userAppDataPath == null
          ? null
          : join(userAppDataPath, 'tekartik', 'process_run', 'env.yaml'));
}

/// Get the local env file path
String getLocalEnvFilePath() => join(
    Directory.current?.path ?? '.', '.dart_tool', 'process_run', 'env.yaml');
