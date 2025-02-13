import 'package:process_run/shell.dart' as io;
import 'package:process_run/src/io/env_var_set_io.dart';
import 'package:process_run/src/shell.dart';
import 'bin/shell/import.dart';
import 'shell_common.dart';

/// Shell implementation using io.
class ShellIo extends Shell with ShellMixin {
  /// Shell implementation using io.
  ShellIo({required ShellOptions options}) : super.implWithOptions(options);

  @override
  Future<io.Shell> shellVarOverride(
    String name,
    String? value, {
    bool? local,
  }) async {
    var helper = ShellEnvVarSetIoHelper(
      shell: this,
      local: local ?? true,
      verbose: options.verbose,
    );
    var env = await helper.setValue(name, value);
    return context.newShell(options: options.clone(shellEnvironment: env));
  }
}

/// Shell exception io
class ShellExceptionIo implements ShellException {
  /// implementation
  final io.ShellException impl;

  /// Shell exception io
  ShellExceptionIo(this.impl);

  @override
  String get message => impl.message;

  @override
  ProcessResult? get result => impl.result;
}
