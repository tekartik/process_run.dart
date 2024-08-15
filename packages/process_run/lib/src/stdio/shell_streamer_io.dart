import 'package:process_run/src/io/io.dart' as io;

import 'package:process_run/src/stdio/stdio.dart';

/// Stdio streamer.
class ShellOutputLinesStreamerIo
    with ShellOutputLinesStreamerMixin
    implements ShellOutputLinesStreamer {
  /// stdout.
  late final io.IOSink _stdout;

  /// stderr.
  late final io.IOSink _stderr;

  /// Log an info message.
  void log(String message) {
    if (current) {
      _stdout.writeln(message);
    } else {
      lines.add(StdioStreamLine(StdioStreamType.out, message));
    }
  }

  @override
  set current(bool current) {
    if (this.current != current) {
      super.current = current;
      if (current) {
        dump();
      }
    }
  }

  /// Log an error message.
  void error(String message) {
    if (current) {
      _stderr.writeln(message);
    } else {
      lines.add(StdioStreamLine(StdioStreamType.err, message));
    }
  }

  /// Stdio streamer.could become true at any moment!
  ShellOutputLinesStreamerIo({io.IOSink? stdout, io.IOSink? stderr}) {
    _stdout = stdout ?? io.ioStdout;
    _stderr = stderr ?? io.ioStderr;
    outController.stream.listen((line) {
      log(line);
    });
    errController.stream.listen((line) {
      error(line);
    });
  }

  // No effect by default (in memory), overriden on io.
  @override
  void dump() {
    for (var line in lines) {
      if (line.type == StdioStreamType.out) {
        _stdout.writeln(line.line);
      } else {
        _stderr.writeln(line.line);
      }
    }
  }

  /// Close.
  @override
  void close() {
    mixinDispose();
  }
}
