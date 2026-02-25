import 'package:process_run/shell.dart' as io;
import 'package:process_run/src/io/env_var_set_io.dart';
import 'package:process_run/src/shell.dart';
import 'package:process_run/utils/shell_context.dart';
import 'bin/shell/import.dart';
import 'shell_common.dart';

/// Shell implementation using io.
class ShellIo extends Shell with ShellMixin {
  @override
  final ShellContext context;

  /// Shell implementation using io.
  ShellIo({required this.context, required ShellOptions options})
    : super.implWithOptions(options);

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
    return context.shell(options: options.clone(shellEnvironment: env));
  }
}
