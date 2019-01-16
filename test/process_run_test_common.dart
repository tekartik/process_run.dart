import 'dart:async';
import 'dart:io';

import "package:async/async.dart";
import 'package:dev_test/test.dart';
import 'package:path/path.dart';

String get projectTop => '.';

String get testDir => join('.dart_tool', 'process_run', 'test');

String get echoScriptPath => join(projectTop, 'example', 'echo.dart');

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

  @override
  Future get done => _doneCompleter.future;
  final _doneCompleter = Completer<dynamic>();

  final Func0 _onDone;

  /// Creates a new sink.
  ///
  /// If [onDone] is passed, it's called when the user calls [close]. Its result
  /// is piped to the [done] future.
  TestSink({onDone()}) : _onDone = onDone ?? (() {});

  @override
  void add(T event) {
    results.add(Result<T>.value(event));
  }

  @override
  void addError(error, [StackTrace stackTrace]) {
    results.add(Result<T>.error(error, stackTrace));
  }

  @override
  Future addStream(Stream<T> stream) {
    var completer = Completer.sync();
    stream.listen(add, onError: addError, onDone: completer.complete);
    return completer.future;
  }

  @override
  Future close() {
    _isClosed = true;
    _doneCompleter.complete(Future.microtask(_onDone));
    return done;
  }
}
