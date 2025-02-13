// ignore: import_of_legacy_library_into_null_safe
import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/io/io.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

/// Shell command base class
class ShellBinCommand {
  /// Optional parent
  ShellBinCommand? parent;

  /// Name of the command
  String name;

  /// Default parser
  ArgParser get parser => _parser ??= ArgParser(allowTrailingOptions: false);
  FutureOr<bool> Function()? _onRun;
  ArgParser? _parser;

  /// Parser results
  late ArgResults results;
  bool? _verbose;

  /// Set before run
  bool get verbose => _verbose ??= parent?.verbose ?? false;

  String? _description;

  /// Description of the command
  String? get description => _description;
  Version? _version;

  /// Version of the command
  Version? get version => _version ??= parent?.version;

  /// print the name and description
  void printNameDescription() {
    stdout.writeln('$name${parent != null ? '' : ' ${version.toString()}'}');
    if (description != null) {
      stdout.writeln('  $description');
    }
  }

  /// Print the usage
  void printUsage() {
    printNameDescription();
    stdout.writeln();
    stdout.writeln(parser.usage);
    if (_commands.isNotEmpty) {
      printCommands();
    }
  }

  /// Prepend an em
  void printCommands() {
    _commands.forEach((name, value) {
      value.printNameDescription();
    });
    stdout.writeln();
  }

  /// Print the base usage
  void printBaseUsage() {
    printNameDescription();
    if (_commands.isNotEmpty) {
      stdout.writeln();
      printCommands();
    } else {
      stdout.writeln();
      stdout.writeln(parser.usage);
    }
  }

  /// Parse the arguments
  ArgResults parse(List<String> arguments) {
    results = parser.parse(arguments);
    if (parent == null) {
      // Handle verbose
      _verbose = getFlag(flagVerbose);
    }
    return results;
  }

  /// Parse and run the command
  @nonVirtual
  FutureOr<bool> parseAndRun(List<String> arguments) {
    parse(arguments);
    return run();
  }

  final _commands = <String, ShellBinCommand>{};

  /// Shell bin command
  ShellBinCommand({
    required this.name,
    Version? version,
    ArgParser? parser,
    ShellBinCommand? parent,
    String? description,
  }) {
    //_onRun = onRun;
    _parser = parser;
    _description = description;
    _version = version;
    // read or create
    parser = this.parser;
    // Add missing common commands
    if (parent == null) {
      parser.addFlag(
        flagVersion,
        help: 'Print the command version',
        negatable: false,
      );
      parser.addFlag(
        flagVerbose,
        abbr: 'v',
        help: 'Verbose mode',
        negatable: false,
      );
    }
    parser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
  }

  /// Add a command
  void addCommand(ShellBinCommand command) {
    parser.addCommand(command.name, command.parser);
    _commands[command.name] = command;
    command.parent = this;
  }

  /// To override
  ///
  /// return true if handled.
  @visibleForOverriding
  FutureOr<bool> onRun() {
    if (_onRun != null) {
      return _onRun!();
    }
    return false;
  }

  /// Get a flag
  bool getFlag(String name) => results.flag(name);

  /// Run
  @nonVirtual
  FutureOr<bool> run() async {
    // Handle version first
    if (parent == null) {
      // Handle verbose
      _verbose = getFlag(flagVerbose);

      final hasVersion = getFlag(flagVersion);
      if (hasVersion) {
        stdout.writeln(version);
        return true;
      }
    }
    // Handle help
    final help = results[flagHelp] as bool;

    if (help) {
      printUsage();
      return true;
    }

    // Find the command if any
    var command = results.command;

    var shellCommand = _commands[command?.name];
    if (shellCommand != null) {
      // Set the result in the the shell command
      shellCommand.results = command!;
      return shellCommand.run();
    }

    var ran = await onRun();
    if (!ran) {
      stderr.writeln('No command ran');
      printBaseUsage();
      exit(1);
    }
    return ran;
  }

  @override
  String toString() => 'ShellCommand($name)';
}
