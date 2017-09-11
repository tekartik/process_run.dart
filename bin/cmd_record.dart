#!/usr/bin/env dart
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_record.dart';
import 'package:pub_semver/pub_semver.dart';

Version version = new Version(0, 1, 0);

String get currentScriptName => basenameWithoutExtension(Platform.script.path);

/*
Testing

bin/cmd_record.dart example/echo.dart --stdout out
bin/cmd_record.dart -v -i cat

Global options:
-h, --help          Usage help
-o, --stdout        stdout content as string
-p, --stdout-hex    stdout as hexa string
-e, --stderr        stderr content as string
-f, --stderr-hex    stderr as hexa string
-i, --stdin         Handle first line of stdin
-x, --exit-code     Exit code to return
    --version       Print the command version
*/

const String flagRunInShell = "run-in-shell";
const String flagStdin = "stdin";
const String flagJson = "json";

///
/// write rest arguments as lines
///
main(List<String> arguments) async {
  //setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: false);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose', negatable: false);
  parser.addFlag(flagRunInShell,
      abbr: 's', help: 'RunInShell', negatable: false);
  parser.addFlag(flagJson, abbr: 'j', help: 'Save as json', negatable: false);
  parser.addFlag(flagStdin,
      abbr: 'i',
      help: 'stdin read, need CTRL-C to terminate',
      defaultsTo: false,
      negatable: true);
  parser.addOption('exit-code', abbr: 'x', help: 'Exit code to return');
  parser.addFlag('version',
      help: 'Print the command version', negatable: false);

  ArgResults _argResults = parser.parse(arguments);

  bool help = _argResults['help'];
  bool verbose = _argResults['verbose'];
  bool runInShell = _argResults[flagRunInShell];
  bool recordStdin = _argResults[flagStdin];
  bool json = _argResults[flagJson];

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

  bool displayVersion = _argResults['version'];

  if (displayVersion) {
    stderr.writeln('${currentScriptName} version ${version}');
    stderr.writeln('VM: ${Platform.resolvedExecutable} ${Platform.version}');
    return;
  }

  if (_argResults.rest.isEmpty) {
    stderr.writeln('Need a command');
    exit(1);
  }

  // first agument is executable, remaining is arguments
  String cmdExecutable = _argResults.rest.first;
  List<String> cmdArguments = _argResults.rest.sublist(1);

  History history;
  IOSink ioSink;
  if (json || verbose) {
    history = new History();
  } else {
    ioSink = new File("cmd_record.log").openWrite(mode: FileMode.WRITE);
  }

  await record(cmdExecutable, cmdArguments,
      runInShell: runInShell,
      recordStdin: recordStdin,
      history: history,
      dumpSink: ioSink);

  if (verbose) {
    dump(history);
  }

  if (history != null) {
    await new File("cmd_record.json").writeAsString(JSON.encode(history));
  }
}
