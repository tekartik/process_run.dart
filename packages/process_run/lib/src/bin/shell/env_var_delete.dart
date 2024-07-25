import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/env.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/io/env_var_delete_io.dart';
import 'package:process_run/src/io/io.dart';

/// Delete an environment variable from a user/local config file
class ShellEnvVarDeleteCommand extends ShellEnvCommandBase {
  late final _helper = ShellEnvVarDeleteIoHelper(
      shell: Shell(), local: local, verbose: verbose ?? false);

  /// Delete an environment variable from a user/local config file
  ShellEnvVarDeleteCommand()
      : super(
          name: 'delete',
          description:
              'Delete an environment variable from a user/local config file',
        );

  @override
  void printUsage() {
    stdout.writeln('ds env var delete <name> [<name2>...]');
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    var rest = results.rest;
    if (rest.isEmpty) {
      stderr.writeln('At least 1 arguments expected');
      exit(1);
    } else {
      await _helper.deleteMulti(rest);
      return true;
    }
  }
}

/// Direct shell env Var Set run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvVarDeleteCommand().parseAndRun(arguments);
}
