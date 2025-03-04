import 'package:process_run/src/io/io.dart';

import 'package:process_run/src/platform/platform_common.dart';
import 'package:process_run/src/shell_context_common.dart';
import 'package:process_run/src/shell_context_io.dart';

/// true if we are on windows
bool get platformIoIsWindows => Platform.isWindows;

/// Global shell context
final shellContextIo = ShellContextIo();

/// Get the global shell context
ShellContext get shellContextDefault =>
    shellContextPlatformOrNull ??= shellContextIo;
