import 'package:process_run/src/io/io.dart' as io;

import 'package:process_run/src/stdio/stdio.dart';

/// Stdio streamer.
class ShellOutputLinesStreamerIo
    with ShellOutputLinesStreamerMixin
    implements ShellOutputLinesStreamer {
  late final io.IOSink stdout;
  late final io.IOSink stderr;
  void log(String message) {
    if (current) {
      stdout.writeln(message);
    } else {
      lines.add(StdioStreamLine(StdioStreamType.out, message));
    }
  }

  void error(String message) {
    if (current) {
      stderr.writeln(message);
    } else {
      lines.add(StdioStreamLine(StdioStreamType.err, message));
    }
  }

  /// Stdio streamer.could become true at any moment!
  ShellOutputLinesStreamerIo(
      {bool? current = false, io.IOSink? stdout, io.IOSink? stderr}) {
    this.stdout = stdout ?? io.ioStdout;
    this.stderr = stderr ?? io.ioStderr;
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
          stdout.writeln(line.line);
        } else {
          stderr.writeln(line.line);
        }
      }
    }
  }
}
