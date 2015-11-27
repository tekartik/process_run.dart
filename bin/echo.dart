#!/usr/bin/env dart
library tekartik_process.bin.echo;

import 'dart:io';

import 'package:path/path.dart';
import 'package:args/args.dart';
import 'package:command/hex_utils.dart';
import 'package:pub_semver/pub_semver.dart';

Version version = new Version(0, 0, 1);
String get currentScriptName => basenameWithoutExtension(Platform.script.path);

///
/// write rest arguments as lines
///
main(List<String> arguments) async {
  //setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: false);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  parser.addOption('stdout',
      abbr: 'o', help: 'stdout content as string', defaultsTo: null);
  parser.addOption('stdout-hex',
      abbr: 'p', help: 'stdout as hexa string', defaultsTo: null);
  parser.addOption('stderr',
      abbr: 'e', help: 'stderr content as string', defaultsTo: null);
  parser.addOption('stderr-hex',
      abbr: 'f', help: 'stderr as hexa string', defaultsTo: null);
  parser.addFlag('stdin',
      abbr: 'i', help: 'Handle first line of stdin', negatable: false);
  parser.addOption('exit-code', abbr: 'x', help: 'Exit code to return');
  parser.addFlag('version',
      help: 'Print the command version', negatable: false);

  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult['help'];

  _printUsage() {
    stdout.writeln('Echo utility');
    stdout.writeln();
    stdout.writeln('Usage: ${currentScriptName} <command> [<arguments>]');
    stdout.writeln();
    stdout.writeln('Example: ${currentScriptName} -o "Hello world"');
    stdout.writeln('will display "Hellow world"');
    stdout.writeln();
    stdout.writeln("Global options:");
    stdout.writeln(parser.usage);
  }

  if (help) {
    _printUsage();
    return;
  }

  bool displayVersion = _argsResult['version'];

  if (displayVersion) {
    stdout.write('${currentScriptName} version ${version}');
    stdout.writeln('VM: ${Platform.resolvedExecutable} ${Platform.version}');
    return;
  }

  // handle stdin if asked for it
  if (_argsResult['stdin']) {
    stdout.write(stdin.readLineSync());
  }
  // handle stdout
  String outputText = _argsResult['stdout'];
  if (outputText != null) {
    stdout.write(outputText);
  }
  String hexOutputText = _argsResult['stdout-hex'];
  if (hexOutputText != null) {
    stdout.add(hexToBytes(hexOutputText));
  }
  // handle stderr
  String stderrText = _argsResult['stderr'];
  if (stderrText != null) {
    stderr.write(stderrText);
  }
  String stderrHexTest = _argsResult['stderr-hex'];
  if (stderrHexTest != null) {
    stderr.add(hexToBytes(stderrHexTest));
  }

  // handle the rest, default to output
  for (String rest in _argsResult.rest) {
    stdout.writeln(rest);
  }

  // exit code!
  String exitCodeText = _argsResult['exit-code'];
  if (exitCodeText != null) {
    exit(int.parse(exitCodeText));
  }
}
