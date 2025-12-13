#!/usr/bin/env dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: import_of_legacy_library_into_null_safe
import 'package:args/args.dart';
import 'package:process_run/shell.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

import 'hex_utils.dart';

Version echoVersion = Version(0, 1, 1);

/*
Global options:
-h, --help          Usage help
-o, --stdout        stdout content as string
-p, --stdout-hex    stdout as hexa string
-e, --stderr        stderr content as string
-f, --stderr-hex    stderr as hexa string
-i, --stdin         Handle first line of stdin
-l, --write-line    Write an additional new line
-x, --exit-code     Exit code to return
    --version       Print the command version
*/

///
/// write rest arguments as lines
///
Future main(List<String> arguments) async {
  //setupQuickLogging();

  final parser = ArgParser(allowTrailingOptions: false);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose', negatable: false);
  parser.addOption(
    'stdout',
    abbr: 'o',
    help: 'stdout content as string',
    defaultsTo: null,
  );
  parser.addOption(
    'stdout-hex',
    abbr: 'p',
    help: 'stdout as hexa string',
    defaultsTo: null,
  );
  parser.addOption(
    'stdout-env',
    abbr: 'r',
    help: 'echo env variable to stdout',
    defaultsTo: null,
  );
  parser.addOption(
    'stderr',
    abbr: 'e',
    help: 'stderr content as string',
    defaultsTo: null,
  );
  parser.addOption(
    'stderr-hex',
    abbr: 'f',
    help: 'stderr as hexa string',
    defaultsTo: null,
  );
  parser.addFlag(
    'write-line',
    abbr: 'l',
    help: 'Write an additional new line',
    negatable: false,
  );
  parser.addFlag(
    'stdin',
    abbr: 'i',
    help: 'Handle first line of stdin',
    negatable: false,
  );
  parser.addOption('wait', help: 'Wait milliseconds');
  parser.addFlag(
    'all-env',
    help: 'Display all environment (vars and paths) in json pretty print',
    negatable: false,
  );
  parser.addOption('exit-code', abbr: 'x', help: 'Exit code to return');
  parser.addFlag(
    'version',
    help: 'Print the command version',
    negatable: false,
  );

  final argsResult = parser.parse(arguments);

  int? parseInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '');
  }

  final help = argsResult.flag('help');
  final version = argsResult.flag('version');
  final wait = parseInt(argsResult['wait']);
  final writeLine = argsResult.flag('write-line');

  if (version) {
    stdout.write(version);
    return;
  }

  if (wait != null) {
    await Future<void>.delayed(Duration(milliseconds: wait));
  }

  void printUsage() {
    stdout.writeln('Echo utility');
    stdout.writeln();
    stdout.writeln('Usage: echo <command> [<arguments>]');
    stdout.writeln();
    stdout.writeln("Example: echo -o 'Hello world'");
    stdout.writeln("will display 'Hello world'");
    stdout.writeln();
    stdout.writeln('Global options:');
    stdout.writeln(parser.usage);
  }

  if (help) {
    printUsage();
    return;
  }

  // handle stdin if asked for it
  if (argsResult.flag('stdin')) {
    final lineSync = stdin.readLineSync();
    if (lineSync != null) {
      stdout.write(lineSync);
    }
    if (writeLine) {
      stdout.writeln();
    }
  }
  // handle stdout
  final outputText = argsResult['stdout'] as String?;
  if (outputText != null) {
    stdout.write(outputText);
    if (writeLine) {
      stdout.writeln();
    }
  }
  final hexOutputText = argsResult['stdout-hex'] as String?;
  if (hexOutputText != null) {
    stdout.add(hexToBytes(hexOutputText));
    if (writeLine) {
      stdout.writeln();
    }
  }
  // handle stderr
  final stderrText = argsResult['stderr'] as String?;
  if (stderrText != null) {
    stderr.write(stderrText);
    if (writeLine) {
      stderr.writeln();
    }
  }
  final stderrHexTest = argsResult['stderr-hex'] as String?;
  if (stderrHexTest != null) {
    stderr.add(hexToBytes(stderrHexTest));
    if (writeLine) {
      stderr.writeln();
    }
  }

  final envVar = argsResult['stdout-env'] as String?;
  if (envVar != null) {
    stdout.write(Platform.environment[envVar] ?? '');
    if (writeLine) {
      stdout.writeln();
    }
  }

  if (argsResult.flag('all-env')) {
    var env = ShellEnvironment(environment: Platform.environment);
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(env.toJson()));
  }

  // handle the rest, default to output
  for (final rest in argsResult.rest) {
    stdout.writeln(rest);
  }

  // exit code!
  final exitCodeText = argsResult['exit-code'] as String?;
  if (exitCodeText != null) {
    exit(int.parse(exitCodeText));
  }
}
