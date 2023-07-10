import 'package:process_run/shell.dart' as io;
import 'package:process_run/src/io/env_var_set_io.dart';

import 'shell_common.dart';

class ShellIo extends Shell with ShellMixin {
  ShellIo({
    required ShellOptions options,
  }) : super.implWithOptions(options);

  @override
  Future<io.Shell> shellVarOverride(String name, String? value,
      {bool? local}) async {
    var helper = ShellEnvVarSetIoHelper(
        shell: this, local: local ?? true, verbose: options.verbose);
    var env = await helper.setValue(name, value);
    return context.newShell(options: options.clone(shellEnvironment: env));
  }
}

class ShellExceptionIo implements ShellException {
  final io.ShellException impl;

  ShellExceptionIo(this.impl);

  @override
  String get message => impl.message;

  @override
  ProcessResult? get result => impl.result;
}
