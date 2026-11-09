import 'dart:convert';

import 'package:process_run/src/characters.dart';
import 'package:process_run/src/io/io.dart';
import 'package:process_run/src/user_config.dart';
import 'package:yaml/yaml.dart';

/// [value] as a yaml scalar: as is when it reads back as the same string,
/// double quoted otherwise (json is valid yaml), so that a value such as
/// `a: b` cannot corrupt the file.
String _yamlScalar(String value) {
  try {
    var map = loadYaml('key: $value');
    if (map is Map && map['key'] == value) {
      return value;
    }
  } catch (_) {
    // Invalid as is, quoted
  }
  return jsonEncode(value);
}

/// File content helper
class FileContent {
  /// File content helper
  FileContent(String path) {
    file = File(path);
  }

  /// io file
  late File file;

  /// Read the file
  Future<bool> read() async {
    try {
      lines = LineSplitter.split(await file.readAsString()).toList();
      return true;
    } catch (e) {
      stderr.writeln('Error $e reading $file');
      return false;
    }
  }

  /// Find the index of the top level key
  int indexOfTopLevelKey(List<String> supportedKeys) {
    for (var key in supportedKeys) {
      for (var i = 0; i < lines!.length; i++) {
        var line = lines![i];
        // Assume a proper format
        if (line.startsWith(key) &&
            line.substring(key.length).trim().startsWith(':')) {
          return i;
        }
      }
    }
    return -1;
  }

  /// Expands the inline value of the top level key line at [index] (`path:
  /// ~/bin`, `path: [a, b]`, `var: {A: b}`) to block lines, so that block
  /// items can be inserted and removed below it. A scalar becomes a list item
  /// when [scalarAsListItem] is true (a single path), it is kept otherwise.
  void _expandInlineValue(int index, {required bool scalarAsListItem}) {
    var line = lines![index];
    var colon = line.indexOf(':');
    if (colon < 0) {
      return;
    }
    var inline = line.substring(colon + 1).trim();
    if (inline.isEmpty || inline.startsWith('#')) {
      return;
    }
    YamlNode node;
    try {
      node = loadYamlNode(inline);
    } catch (_) {
      // A flow value on several lines, kept as is.
      return;
    }
    List<String> block;
    if (node is YamlMap) {
      block = [
        for (var entry in node.nodes.entries)
          '  ${(entry.key as YamlNode).span.text}: ${entry.value.span.text}',
      ];
    } else if (node is YamlList) {
      block = [for (var item in node.nodes) '  - ${item.span.text}'];
    } else if (node is YamlScalar && node.value == null) {
      block = [];
    } else if (node is YamlScalar && scalarAsListItem) {
      block = ['  - ${node.span.text}'];
    } else {
      return;
    }
    lines!.replaceRange(index, index + 1, [
      '${line.substring(0, colon)}:',
      ...block,
    ]);
  }

  /// Write the file
  Future<void> write() async {
    var content = lines!.join(Platform.isWindows ? '\r\n' : '\n');
    await file.parent.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }

  /// Check if the list is a top level key
  static bool isTopLevelKey(String line) {
    if (startsWithWhitespace(line)) {
      return false;
    }
    if (line.startsWith('#')) {
      return false;
    }
    return true;
  }

  /// Supported top level [parentKeys]
  bool writeKeyValue(
    List<String> parentKeys,
    String key, {
    bool delete = false,
    String? value,
  }) {
    // Remove alias header
    var modified = false;
    var insertTopLevelKey = false;
    var index = indexOfTopLevelKey(parentKeys);
    if (index < 0) {
      index = lines!.length;
      insertTopLevelKey = true;
    } else {
      _expandInlineValue(index, scalarAsListItem: false);
      // Skip top level key
      index++;
      // Remove existing alias
      for (var i = index; i < lines!.length; i++) {
        // Until first non space, non comment stat
        var line = lines![i];
        if (isTopLevelKey(line)) {
          break;
        } else if (line.trimLeft().startsWith('$key:')) {
          // Found! remove
          // Remove last first!
          modified = true;
          lines!.removeAt(i);
          break;
        }
      }
    }
    if (insertTopLevelKey) {
      // Insert top header
      modified = true;
      lines!.insert(index++, '${parentKeys.first}:');
    }
    if (!delete) {
      modified = true;
      lines!.insert(index++, '  $key: ${_yamlScalar(value ?? '')}');
    }

    return modified;
  }

  /// lines
  List<String>? lines;
}

/// Env file content helper
class EnvFileContent extends FileContent {
  /// Env file content helper
  EnvFileContent(super.path);

  /// add an alias
  bool addAlias(String alias, String command) =>
      writeKeyValue(userConfigAliasKeys, alias, value: command);

  /// delete an alias
  bool deleteAlias(String alias) =>
      writeKeyValue(userConfigAliasKeys, alias, delete: true);

  /// add a variable
  bool addVar(String key, String value) =>
      writeKeyValue(userConfigVarKeys, key, value: value);

  /// delete a variable
  bool deleteVar(String key) =>
      writeKeyValue(userConfigVarKeys, key, delete: true);

  /// Put the paths at the top
  bool prependPaths(List<String> paths) => writePaths(paths);

  /// Delete the paths
  bool deletePaths(List<String> paths) => writePaths(paths, delete: true);

  /// Write paths
  bool writePaths(List<String> paths, {bool delete = false}) {
    // Remove alias header
    var index = indexOfTopLevelKey(userConfigPathKeys);
    var insertTopLevelKey = false;
    var modified = false;
    if (index < 0) {
      index = lines!.length;
      insertTopLevelKey = true;
    } else {
      _expandInlineValue(index, scalarAsListItem: true);
      // Skip top level key
      index++;
      // Remove existing paths
      for (var path in paths) {
        for (var i = index; i < lines!.length; i++) {
          // Until first non space, non comment stat
          var line = lines![i];
          if (FileContent.isTopLevelKey(line)) {
            break;
          } else if (line.trim() == '- $path') {
            // Found! remove
            // Remove last first!
            modified = true;
            lines!.removeAt(i);
            break;
          }
        }
      }
    }
    if (insertTopLevelKey) {
      // Insert top header
      modified = true;
      lines!.insert(index++, '${userConfigPathKeys.first}:');
    }
    if (!delete) {
      for (var path in paths) {
        modified = true;
        lines!.insert(index++, '  - $path');
      }
    }

    return modified;
  }
}
