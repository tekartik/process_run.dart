import 'package:process_run/shell.dart';

/// Helper to get environment variables
class ShellEnvVarGetIoHelper {
  /// Helper to get environment variables
  ShellEnvVarGetIoHelper();

  /// get multiple environment variables
  Map<String, String> getMulti(List<String> keys) {
    Map<String, String> map = ShellEnvironment().vars;
    map = Map<String, String>.from(map)
      ..removeWhere((key, value) => !keys.contains(key));
    return map;
  }

  /// get a single environment variable
  String? get(String key) {
    var value = ShellEnvironment().vars[key];
    return value;
  }
}
