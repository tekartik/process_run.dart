import 'package:process_run/src/stdio/shell_streamer_io.dart';

export 'package:process_run/src/platform/platform.dart' show shellContext;

/// Shell streamer platform implementation.
class ShellOutputLinesStreamerPlatform extends ShellOutputLinesStreamerIo {
  /// Shell streamer platform implementation.
  ShellOutputLinesStreamerPlatform({super.stdout, super.stderr});
}
