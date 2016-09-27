@TestOn("vm")
library command.test.process_command_test;

import 'package:dev_test/test.dart';
import 'dart:mirrors';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:async';
import "package:async/async.dart";

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

/// A [StreamSink] that collects all events added to it as results.
///
/// This is used for testing code that interacts with sinks.
class TestSink<T> implements StreamSink<T> {
  /// The results corresponding to events that have been added to the sink.
  final results = <Result<T>>[];

  /// Whether [close] has been called.
  bool get isClosed => _isClosed;
  var _isClosed = false;

  Future get done => _doneCompleter.future;
  final _doneCompleter = new Completer();

  final Function _onDone;

  /// Creates a new sink.
  ///
  /// If [onDone] is passed, it's called when the user calls [close]. Its result
  /// is piped to the [done] future.
  TestSink({onDone()}) : _onDone = onDone ?? (() {});

  void add(T event) {
    results.add(new Result<T>.value(event));
  }

  void addError(error, [StackTrace stackTrace]) {
    results.add(new Result<T>.error(error, stackTrace));
  }

  Future addStream(Stream<T> stream) {
    var completer = new Completer.sync();
    stream.listen(add, onError: addError, onDone: completer.complete);
    return completer.future;
  }

  Future close() {
    _isClosed = true;
    _doneCompleter.complete(new Future.microtask(_onDone));
    return done;
  }
}
