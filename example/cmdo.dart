#!/usr/bin/env dart
library tekartik_cmdo.bin.cmdo;

import 'dart:io';

import 'package:path/path.dart';
import 'package:args/args.dart';
import 'package:cmdo/cmdo.dart';
import 'package:cmdo/cmdo_io.dart';
import 'package:cmdo/cmdo_dry.dart';

const String _HELP = 'help';
const String _LOG = 'log';
const String _VERBOSE = 'verbose';
const String _DRY_RUN = 'dry-run';
const String _VERSION = "version";

String get currentScriptName => basenameWithoutExtension(Platform.script.path);

///
/// clone hg or git repository
///
main(List<String> arguments) async {
  //setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: false);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag(_VERBOSE, abbr: 'v', help: 'Verbose', negatable: false);

  parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');
  parser.addFlag(_DRY_RUN,
      abbr: 'd',
      help: 'Do not execute, show the command executed',
      negatable: false);
  parser.addFlag(_VERSION,
      help: 'Print the cmdo version and VM version', negatable: false);

  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult[_HELP];

  _printUsage() {
    stdout.writeln('Cmdo utility');
    stdout.writeln();
    stdout.writeln('Usage: ${currentScriptName} <command> [<arguments>]');
    stdout.writeln();
    stdout.writeln('Example: ${currentScriptName} help');
    stdout.writeln('will display system help');
    stdout.writeln();
    stdout.writeln("Global options:");
    stdout.writeln(parser.usage);
  }

  if (help) {
    _printUsage();
    return;
  }
  bool dryRun = _argsResult[_DRY_RUN];
  //String logLevel = _argsResult[_LOG];
  bool verbose = _argsResult[_VERBOSE];
  if (verbose) {
    // for now just set the debug flag
    debugCmdoIo = true;
  }
  bool version = _argsResult[_VERSION];

  if (version == true) {
    stdout.writeln('VM: ${Platform.resolvedExecutable} ${Platform.version}');
    return;
  }

  List<String> rest = _argsResult.rest;
  if (rest.isEmpty) {} else {
    String executable = rest.first;
    List<String> arguments = rest.sublist(1);

    CommandExecutor executor;
    if (dryRun) {
      executor = dry;
    } else {
      executor = io;
    }

    CommandInput input = commandInput(executable, arguments, connectIo: true);
    await executor.runInput(input);
  }
}
