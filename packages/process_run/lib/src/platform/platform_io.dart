import 'package:process_run/src/io/io.dart';

import 'package:process_run/src/platform/platform_common.dart';
import 'package:process_run/src/shell_context_common.dart';
import 'package:process_run/src/shell_context_io.dart';

bool get platformIoIsWindows => Platform.isWindows;

/// Global shell context
final shellContextIo = ShellContextIo();

ShellContext get shellContext => shellContextPlatformOrNull ??= shellContextIo;
