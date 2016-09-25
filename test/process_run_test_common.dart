@TestOn("vm")
library command.test.process_command_test;

import 'package:dev_test/test.dart';
import 'dart:mirrors';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:async';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;
String get testDir => dirname(testScriptPath);

String get echoScriptPath => join(dirname(testDir), 'example', 'echo.dart');

// does not exists
String get dummyExecutable => join(dirname(testDir), 'example', 'dummy');

Stream<List<int>> testStdin = stdin.asBroadcastStream();
