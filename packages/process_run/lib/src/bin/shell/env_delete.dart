import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/io/io.dart';

import 'env.dart';

/// Shell env delete command.
class ShellEnvDeleteCommand extends ShellEnvCommandBase {
  /// Shell env delete command.
  ShellEnvDeleteCommand()
      : super(name: 'delete', description: 'Delete the environment file') {
    parser.addFlag(flagForce,
        abbr: 'f', help: 'Force deletion, no prompt', negatable: false);
  }

  @override
  FutureOr<bool> onRun() async {
    var path = envFilePath;
    if (verbose!) {
      stdout.writeln('envFilePath: $path');
    }
    var force = getFlag(flagForce)!;

    if (force ||
        await promptConfirm('Confirm that you want to delete file ($label)')) {
      stdout.writeln('  $path');
      try {
        await File(path!).delete();
        stdout.writeln('Deleted $path');
      } catch (e) {
        stderr.writeln('Error $e deleting $path');
        exit(1);
      }

      return true;
    }
    exit(1);
  }
}

/// Direct shell env Edit dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvDeleteCommand().parseAndRun(arguments);
}
