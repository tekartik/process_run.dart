import 'package:process_run/src/stdio/stdio.dart';

class ShellOutputLinesStreamerPlatform extends ShellOutputLinesStreamerMemory {
  ShellOutputLinesStreamerPlatform({super.current, super.stdout, super.stderr});
}
