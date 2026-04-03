import 'dart:convert';
import 'dart:typed_data';

import 'package:process_run/src/platform/platform.dart';

import 'common/import.dart';

/// Basic bi-directionnal shell Uint8List controller.
///
/// Only tested for stdin for now, not public
///
/// Use either sink for stdout/stderr or binaryStream for stdin
///
/// Usage:
/// ```dart
/// var controller = ShellUint8ListController();
/// var shell = Shell(stdout: controller.sink, verbose: false);
/// controller.stream.listen((event) {
///   // Handle output
///
///   // ...
///
///   // If needed kill the shell
///   shell.kill();
/// });
/// try {
///   await shell.run('dart echo.dart some_text');
/// } on ShellException catch (_) {
///   // We might get a shell exception
/// }
/// ```
class ShellUint8ListController {
  /// Encoding to use
  late final Encoding encoding;
  late StreamController<Uint8List> _controller;

  /// Create a shell lines controller.
  ShellUint8ListController({Encoding? encoding}) {
    this.encoding = encoding ?? shellContext.encoding;
    // Must be sync!
    _controller = StreamController<Uint8List>(sync: true);
  }

  /// The sink for the Shell stderr/stdout
  StreamSink<Uint8List> get sink => _controller.sink;

  /// The stream to listen to
  Stream<Uint8List> get stream => _controller.stream;

  /// Dispose the controller.
  void close() {
    _controller.close();
  }
}
