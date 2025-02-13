import 'package:process_run/src/bin/shell/env.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/io/env_var_get_io.dart';
import 'package:process_run/src/io/io.dart';

import 'dump.dart';

/// Get an environment variable from a user/local config file
class ShellEnvVarGetCommand extends ShellEnvCommandBase {
  late final _helper = ShellEnvVarGetIoHelper();

  /// Get an environment variable from a user/local config file
  ShellEnvVarGetCommand()
    : super(name: 'get', description: 'Get environment variable');

  @override
  void printUsage() {
    stdout.writeln('ds env var get <name1> [<name2> ...]');
    stdout.writeln();
    stdout.writeln('Output if defined:');
    stdout.writeln('  <name>: <value>');
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    var rest = results.rest;
    if (rest.isEmpty) {
      stderr.writeln('At least 1 arguments expected');
      exit(1);
    } else {
      var map = _helper.getMulti(rest);
      if (map.isEmpty) {
        stdout.writeln('not found');
      } else {
        dumpStringMap(map);
      }
      return true;
    }
  }
}

/// Direct shell env Var Set run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvVarGetCommand().parseAndRun(arguments);
}
