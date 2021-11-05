import 'dart:async';
import 'dart:convert';

import 'package:process_run/src/platform/platform.dart';

const windowsDefaultPathExt = <String>['.exe', '.bat', '.cmd', '.com'];

const String windowsEnvPathSeparator = ';';
const String posixEnvPathSeparator = ':';
const envPathKey = 'PATH';

String get envPathSeparator =>
    platformIoIsWindows ? windowsEnvPathSeparator : posixEnvPathSeparator;

/// Write a string line to the ouput
void streamSinkWriteln(StreamSink<List<int>> sink, String message,
    {Encoding? encoding}) {
  encoding ??= shellContext.encoding;
  streamSinkWrite(sink, '$message\n', encoding: encoding);
}

/// Write a string to a to sink
void streamSinkWrite(StreamSink<List<int>> sink, String message,
    {Encoding? encoding}) {
  encoding ??= shellContext.encoding;
  sink.add(encoding.encode(message));
}
