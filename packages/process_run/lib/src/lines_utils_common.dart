import 'dart:convert';
import 'dart:typed_data';

import 'package:process_run/src/platform/platform.dart';
import 'package:process_run/src/shell_common.dart';
import 'package:process_run/src/shell_utils_common.dart';

import 'common/import.dart';

/// Shell lines controller, for the output or the input of a command.
///
/// Use one per direction: give its [sink] as `stdout:`/`stderr:` and listen
/// to its [stream] of lines, or give its [binaryStream] as `stdin:` and
/// [write]/[writeln] to it, [close] being the end of input of the command.
///
/// Output:
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
///
/// Input:
/// ```dart
/// var input = ShellLinesController();
/// var shell = Shell(stdin: input.binaryStream, verbose: false);
/// var done = shell.run('sort');
/// input.writeln('b');
/// input.writeln('a');
/// // End of input: sort then writes its output and exits
/// input.close();
/// print((await done).outLines); // (a, b)
/// ```
class ShellLinesController {
  /// Create a shell lines controller.
  ShellLinesController({Encoding? encoding}) {
    this.encoding = encoding ?? shellContext.encoding;
    // Must be sync!
    _controller = StreamController<List<int>>(sync: true);
  }

  /// Encoding to use
  late final Encoding encoding;
  late StreamController<List<int>> _controller;

  /// Future when done
  Future<void> get done => _controller.done;

  /// Write a string with the specified encoding.
  void write(String message) =>
      streamSinkWrite(sink, message, encoding: encoding);

  /// The sink for the Shell stderr/stdout
  StreamSink<List<int>> get sink => _controller.sink;

  /// The stream to listen to
  Stream<String> get stream =>
      shellStreamLines(_controller.stream, encoding: encoding);

  /// True if the controller is closed.
  bool get isClosed => _controller.isClosed;

  /// The binary stream to listen to, that can be passed to stdin
  Stream<List<int>> get binaryStream => _controller.stream;

  /// Dispose the controller.
  void close() {
    _controller.close();
  }

  /// Write a line.
  void writeln(String message) {
    write('$message\n');
  }
}

/// The text of the bytes of a [line] in [encoding]. A line that is not in
/// this encoding is not lost: it is read as UTF-8, what is not text replaced
/// by U+FFFD.
String _decodeLine(Encoding encoding, List<int> line) {
  try {
    return encoding.decode(line);
  } catch (_) {
    return utf8.decode(line, allowMalformed: true);
  }
}

/// Basic line streaming. Assuming system encoding.
///
/// A line that cannot be decoded with [encoding] is read as UTF-8, its
/// malformed sequences replaced by U+FFFD.
Stream<String> shellStreamLines(
  Stream<List<int>> stream, {
  Encoding? encoding,
}) {
  encoding ??= shellContext.encoding;
  StreamSubscription? subscription;
  List<int>? currentLine;
  const lineFeed = 10; // \n LF
  const carriageReturn = 13; // \r CR
  late StreamController<String> ctlr;

  // devPrint('listen (paused: $paused)');
  void addCurrentLine() {
    // Cleared before being added: a listener pausing when it gets the line
    // calls onPause, hence addCurrentLine, again.
    var line = currentLine;
    currentLine = null;
    if (subscription?.isPaused ?? false) {
      // Do nothing, current line is discarded
    } else {
      if (line != null) {
        ctlr.add(_decodeLine(encoding!, line));
      }
    }
  }

  ctlr = StreamController<String>(
    onPause: () {
      if (shellDebug) {
        // ignore: avoid_print
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
      subscription = stream.listen(
        (data) {
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
        },
        onDone: () {
          // devPrint('onDone');
          // Last one
          addCurrentLine();
          ctlr.close();
        },
        onError: (Object e, StackTrace st) {
          ctlr.addError(e, st);
        },
      );
    },
    onCancel: () {
      // devPrint('onCancel');
      subscription?.cancel();
    },
    sync: true,
  );

  return ctlr.stream;
}
