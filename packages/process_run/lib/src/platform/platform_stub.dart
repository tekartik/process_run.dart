import 'package:process_run/src/platform/platform_common.dart';
import 'package:process_run/src/shell_context_common.dart';
import 'package:process_run/src/shell_context_memory.dart';

/// Only true for IO windows
bool get platformIoIsWindows => false;

/// Never null
ShellContext get shellContextDefault =>
    shellContextPlatformOrNull ??= shellContextMemory;
