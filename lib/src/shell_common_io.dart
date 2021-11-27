import 'dart:async';
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

Future<T> _wrapIoException<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on io.ShellException catch (e) {
    throw ShellExceptionIo(e);
  }
}

class ShellIo implements Shell {
  late final io.Shell impl;

  ShellIo({
    required this.impl,
  });

  Shell _wrapIoShell(io.Shell ioShell) => ShellIo(impl: ioShell);

  @override
  Shell cd(String path) => _wrapIoShell(impl.cd(path));

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    var ioProcessSignal = io.ProcessSignal.sigterm;
    return impl.kill(ioProcessSignal);
  }

  @override
  String get path => impl.path;

  @override
  Shell popd() => _wrapIoShell(impl.popd());

  @override
  Shell pushd(String path) => _wrapIoShell(impl.pushd(path));

  @override
  Future<List<ProcessResult>> run(String script,
          {void Function(Process process)? onProcess}) =>
      _wrapIoException(() async {
        var ioResult = await impl.run(script,
            onProcess: onProcess == null ? null : (io.Process process) {});
        return ioResult
            .map((ioProcessResult) => ProcessResultIo(ioProcessResult))
            .toList();
      });

  @override
  Future<ProcessResult> runExecutableArguments(
          String executable, List<String> arguments,
          {void Function(Process process)? onProcess}) =>
      _wrapIoException(() async {
        return ProcessResultIo(
            await impl.runExecutableArguments(executable, arguments));
      });
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
