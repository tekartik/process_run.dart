import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:yaml/yaml.dart';

List<String> _userPaths;

List<String> get userPaths => _userPaths ??= getUserPaths(null);

// Fix environment with global settings and current dart sdk
List<String> getUserPaths(Map<String, String> environment) {
  var paths = <String>[];
  try {
    // Look for any config file in ~/tekartik/process_run/env.yaml
    var userConfig = loadYaml(
        File(join(userAppDataPath, 'tekartik', 'process_run', 'env.yaml'))
            .readAsStringSync());

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
  } catch (_) {}

  // Add dart path so that dart commands always work!
  paths.add(dartSdkBinDirPath);

  // Add from environment
  paths.addAll(getEnvironmentPaths(environment));

  return paths;
}
