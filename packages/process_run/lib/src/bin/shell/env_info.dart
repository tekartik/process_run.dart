import 'package:path/path.dart';
import 'package:process_run/src/user_config.dart';

import 'import.dart';

/// pub run process_run:shell run
class ShellEnvInfoCommand extends ShellBinCommand {
  /// pub run process_run:shell run
  ShellEnvInfoCommand()
      : super(name: 'info', description: 'Display environment info');

  @override
  void printUsage() {
    stdout.writeln('Run a command');
    stdout.writeln();
    stdout.writeln('Usage: $script env info');
    stdout.writeln('  Environment information');

    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    void displayInfo(String title, String path) {
      var config = loadFromPath(path);
      stdout.writeln('# $title');
      stdout.writeln('file: ${relative(path, from: Directory.current.path)}');
      stdout.writeln('vars: ${config.vars}');
      stdout.writeln('paths: ${config.paths}');
    }

    displayInfo('user_env', getUserEnvFilePath()!);
    displayInfo('local_env', getLocalEnvFilePath());

    return true;
  }
}

/// Direct shell env Alias dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvInfoCommand().parseAndRun(arguments);
}
