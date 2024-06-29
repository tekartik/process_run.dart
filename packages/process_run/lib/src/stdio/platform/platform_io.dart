import 'package:process_run/src/stdio/shell_streamer_io.dart';

export 'package:process_run/src/platform/platform.dart' show shellContext;

class ShellOutputLinesStreamerPlatform extends ShellOutputLinesStreamerIo {
  ShellOutputLinesStreamerPlatform({super.current});
}
