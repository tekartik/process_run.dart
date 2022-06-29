import 'dart:io' as io;

import 'package:process_run/shell.dart' as io;

import 'shell_common.dart';

class ProcessResultIo implements ProcessResult {
  final io.ProcessResult impl;

  ProcessResultIo(this.impl);

  @override
  int get exitCode => impl.exitCode;

  @override
  int get pid => impl.pid;

  @override
  Object? get stderr => impl.stderr;

  @override
  Object? get stdout => impl.stdout;

  @override
  String toString() => 'exitCode $exitCode, pid $pid';
}

/*
Future<T> _wrapIoException<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on io.ShellException catch (e) {
    throw ShellExceptionIo(e);
  }
}
 */

class ShellIo extends Shell {
  ShellIo({
    required ShellOptions options,
  }) : super.implWithOptions(options);
}

class ShellExceptionIo implements ShellException {
  final io.ShellException impl;

  ShellExceptionIo(this.impl);

  @override
  String get message => impl.message;

  @override
  ProcessResult? get result {
    var implResult = impl.result;
    if (implResult != null) {
      return ProcessResultIo(implResult);
    }
    return null;
  }
}
