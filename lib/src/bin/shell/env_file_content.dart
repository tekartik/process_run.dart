import 'dart:convert';
import 'dart:io';

import 'package:process_run/src/characters.dart';
import 'package:process_run/src/user_config.dart';

class FileContent {
  File file;

  FileContent(String path) {
    file = File(path);
  }

  Future<bool> read() async {
    try {
      lines = LineSplitter.split(await file.readAsString()).toList();
      return true;
    } catch (e) {
      stderr.writeln('Error $e reading $file');
      return false;
    }
  }

  int indexOfTopLevelKey(List<String> supportedKeys) {
    for (var key in supportedKeys) {
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        // Assume a proper format
        if (line.startsWith(key) &&
            line.substring(key.length).trim().startsWith(':')) {
          return i;
        }
      }
    }
    return -1;
  }

  Future<void> write() async {
    var content = lines.join(Platform.isWindows ? '\r\n' : '\n');
    await file.parent.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }

  static bool isTopLevelKey(String line) {
    if (startsWithWhitespace(line)) {
      return false;
    }
    if (line.startsWith('#')) {
      return false;
    }
    return true;
  }

  /// Supported top level [configKeys]
  bool addKeyValue(List<String> configKeys, String key, String value) {
    // Remove alias header
    var index = indexOfTopLevelKey(configKeys);
    if (index < 0) {
      index = lines.length;
    } else {
      lines.removeAt(index);
      // Remove existing alias
      for (var i = index; i < lines.length; i++) {
        // Until first non space, non comment stat
        var line = lines[i];
        if (isTopLevelKey(line)) {
          break;
        } else if (line.trimLeft().startsWith('$key:')) {
          // Found! remove
          // Remove last first!
          lines.removeAt(i);
          break;
        }
      }
    }
    lines.insert(index, '${configKeys.first}:');
    lines.insert(index + 1, '  $key: $value');

    return true;
  }

  bool addAlias(String alias, String command) =>
      addKeyValue(userConfigAliasKeys, alias, command);

  bool addVar(String key, String value) =>
      addKeyValue(userConfigVarKeys, key, value);

  List<String> lines;

  Future<bool> prependPaths(List<String> paths) async {
    // Remove alias header
    var index = indexOfTopLevelKey(userConfigPathKeys);
    if (index < 0) {
      index = lines.length;
    } else {
      // Remove it, we'll add it later
      lines.removeAt(index);

      // Remove existing paths
      for (var path in paths) {
        for (var i = index; i < lines.length; i++) {
          // Until first non space, non comment stat
          var line = lines[i];
          if (isTopLevelKey(line)) {
            break;
          } else if (line.trim() == '- $path') {
            // Found! remove
            // Remove last first!

            lines.removeAt(i);
            break;
          }
        }
      }
    }
    lines.insert(index, '${userConfigPathKeys.first}:');
    for (var path in paths) {
      lines.insert(++index, '  - $path');
    }

    return true;
  }
}
