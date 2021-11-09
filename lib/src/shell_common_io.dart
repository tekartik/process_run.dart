import 'dart:async';
import 'dart:io' as io;

import 'package:process_run/shell.dart' as io;
import 'package:process_run/src/mixin/shell_common.dart';
import 'package:process_run/src/shell_context_io.dart';

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

class ShellIo implements Shell {
  final ShellContextIo shellContextIo;
  late final ShellEnvironment environment;
  late final ShellOptions? options;
  late final io.Shell ioShell;

  ShellIo(
      {required this.shellContextIo,
      this.options,
      bool includeParentEnvironment = true,
      ShellEnvironment? environment}) {
    this.environment = environment ?? shellContextIo.shellEnvironment;
    ioShell = io.Shell(
        options: options,
        environment: this.environment,
        includeParentEnvironment: includeParentEnvironment);
  }

  @override
  ShellCommon cd(String path) => ioShell.cd(path);

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    var ioProcessSignal = io.ProcessSignal.sigterm;
    return ioShell.kill(ioProcessSignal);
  }

  @override
  String get path => ioShell.path;

  @override
  ShellCommon popd() => ioShell.popd();

  @override
  ShellCommon pushd(String path) => ioShell.pushd(path);

  @override
  Future<List<ProcessResult>> run(String script,
      {void Function(Process process)? onProcess}) async {
    var ioResult = await ioShell.run(script,
        onProcess: onProcess == null ? null : (io.Process process) {});
    return ioResult
        .map((ioProcessResult) => ProcessResultIo(ioProcessResult))
        .toList();
  }

  @override
  Future<ProcessResult> runExecutableArguments(
      String executable, List<String> arguments,
      {void Function(Process process)? onProcess}) async {
    return ProcessResultIo(
        await ioShell.runExecutableArguments(executable, arguments));
  }
}
