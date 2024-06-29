import 'package:process_run/src/io/io.dart' as io;

import 'package:process_run/src/stdio/stdio.dart';

/// Stdio streamer.
class ShellOutputLinesStreamerIo
    with ShellOutputLinesStreamerMixin
    implements ShellOutputLinesStreamer {
  void log(String message) {
    if (current) {
      io.stdout.writeln(message);
    } else {
      lines.add(StdioStreamLine(StdioStreamType.out, message));
    }
  }

  void error(String message) {
    if (current) {
      io.stderr.writeln(message);
    } else {
      lines.add(StdioStreamLine(StdioStreamType.err, message));
    }
  }

  /// Stdio streamer.could become true at any moment!
  ShellOutputLinesStreamerIo({bool? current = false}) {
    this.current = current;
    outController.stream.listen((line) {
      log(line);
    });
    errController.stream.listen((line) {
      error(line);
    });
  }

  /// Close.
  @override
  void close() {
    mixinDispose();
    if (!current) {
      for (var line in lines) {
        if (line.type == StdioStreamType.out) {
          io.stdout.writeln(line.line);
        } else {
          io.stderr.writeln(line.line);
        }
      }
    }
  }
}
