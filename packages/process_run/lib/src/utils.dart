import 'dart:convert';
import 'package:process_run/src/io/io.dart';

/// Get the shell command file name
String getShellCmdBinFileName(String command) =>
    '$command${Platform.isWindows ? '.bat' : ''}';

//
// [data] can be map a list
// if it is a string, it will try to parse it first
//
/// Convert data to pretty json
String? jsonPretty(dynamic data) {
  if (data is String) {
    dynamic parsed = jsonDecode(data);
    if (parsed != null) {
      data = parsed;
    }
  }
  if (data != null) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return ('Err: $e decoding $data');
    }
  }
  return null;
}
