import 'dart:convert';
import 'dart:typed_data';

import 'package:process_run/src/platform/platform.dart';
import 'package:process_run/src/shell_common.dart';
import 'package:process_run/src/shell_utils_common.dart';

import 'common/import.dart';

/// Basic shell lines controller.
///
/// Usage:
/// ```dart
/// var controller = ShellLinesController();
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
class ShellLinesController {
  late final Encoding encoding;
  late StreamController<List<int>> _controller;

  ShellLinesController({Encoding? encoding}) {
    this.encoding = encoding ?? shellContext.encoding;
    // Must be sync!
    _controller = StreamController<List<int>>(sync: true);
  }

  Future<void> get done => _controller.done;

  /// Write a string with the specified encoding.
  void write(String message) =>
      streamSinkWrite(sink, message, encoding: encoding);

  /// The sink for the Shell stderr/stdout
  StreamSink<List<int>> get sink => _controller.sink;

  /// The stream to listen to
  Stream<String> get stream =>
      shellStreamLines(_controller.stream, encoding: encoding);

  /// Dispose the controller.
  void close() {
    _controller.close();
  }

  void writeln(String message) {
    write('$message\n');
  }
}

/// Basic line streaming. Assuming system encoding
Stream<String> shellStreamLines(Stream<List<int>> stream,
    {Encoding? encoding}) {
  encoding ??= shellContext.encoding;
  StreamSubscription? subscription;
  List<int>? currentLine;
  const lineFeed = 10; // \n LF
  const carriageReturn = 13; // \r CR
  late StreamController<String> ctlr;

  // devPrint('listen (paused: $paused)');
  void addCurrentLine() {
    if (subscription?.isPaused ?? false) {
      // Do nothing, current line is discarded
    } else {
      if (currentLine != null) {
        try {
          ctlr.add(encoding!.decode(currentLine!));
        } catch (_) {
          // Ignore bad encoding
          print('ignoring: $currentLine');
        }
      }
    }
    currentLine = null;
  }

  ctlr = StreamController<String>(
      onPause: () {
        if (shellDebug) {
          print('onPause (paused: ${subscription?.isPaused})');
        }
        // Last one
        addCurrentLine();
        subscription?.pause();
      },
      onResume: () {
        // devPrint('onResume (paused: $paused)');
        if (subscription?.isPaused ?? false) {
          subscription?.resume();
        }
      },
      onListen: () {
        void addToCurrentLine(List<int> data) {
          if (currentLine == null) {
            currentLine = data;
          } else {
            var newCurrentLine = Uint8List(currentLine!.length + data.length);
            newCurrentLine.setAll(0, currentLine!);
            newCurrentLine.setAll(currentLine!.length, data);
            currentLine = newCurrentLine;
          }
        }

        var lastWasCR = false;
        subscription = stream.listen((data) {
          var paused = subscription?.isPaused ?? false;
          // devPrint('read $data (paused: $paused)');
          if (paused) {
            return;
          }
          // look for \n (10)
          var start = 0;

          for (var i = 0; i < data.length; i++) {
            var byte = data[i];
            if (byte == lineFeed || byte == carriageReturn) {
              if (byte == lineFeed) {
                // Ignore CRLF
                if (lastWasCR) {
                  lastWasCR = false;
                  start = i + 1;
                  continue;
                }
              } else {
                lastWasCR = true;
              }
              addToCurrentLine(data.sublist(start, i));
              addCurrentLine();

// Skip it
              start = i + 1;
            } else {
              lastWasCR = false;
            }
          }
          // Store last current line
          if (data.length > start) {
            addToCurrentLine(data.sublist(start, data.length));
          }
        }, onDone: () {
          // Last one
          addCurrentLine();
          ctlr.close();
        }, onError: (Object e, StackTrace st) {
          ctlr.addError(e, st);
        });
      },
      onCancel: () {
        subscription?.cancel();
      },
      sync: true);

  return ctlr.stream;
}
