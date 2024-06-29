import 'dart:io' as io;

import 'package:process_run/src/stdio/stdio.dart';

export 'dart:io' hide stdout, stderr;

export 'package:process_run/src/stdio/stdio.dart'
    show ShellStdio, shellStdioLinesGrouper, ShellStdioExt;

/// Global stdout
io.IOSink get stdout => shellStdioOrNull?.out ?? io.stdout;

/// Global stderr
io.IOSink get stderr => shellStdioOrNull?.err ?? io.stderr;

/// io stdout.
io.IOSink get ioStdout => io.stdout;

/// io stdout.
io.IOSink get ioStderr => io.stderr;
