#!/usr/bin/env dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/process_cmd.dart';
import 'package:pub_semver/pub_semver.dart';

Version version = new Version(0, 1, 0);

String get currentScriptName => basenameWithoutExtension(Platform.script.path);

/*
Testing

bin/cmd_record.dart example/echo.dart --stdout out
bin/cmd_record.dart -i cat

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

class HistoryItem {
  int time;
  String line;

  toJson() => [time, line];
}
class HistorySink implements StreamSink<List<int>> {

  final StreamSink ioSink;

  StreamController<List<int>> lineController = new StreamController(sync: true);

  final Stopwatch stopwatch;
  /// The results corresponding to events that have been added to the sink.
  final results = <HistoryItem>[];

  /// Whether [close] has been called.
  bool get isClosed => _isClosed;
  var _isClosed = false;

  Future get done => _doneCompleter.future;
  final _doneCompleter = new Completer<dynamic>();

  /// Creates a new sink.
  ///
  /// If [onDone] is passed, it's called when the user calls [close]. Its result
  /// is piped to the [done] future.
  HistorySink(this.ioSink, this.stopwatch) {
    lineController.stream.transform(UTF8.decoder).transform(new LineSplitter()).listen((String line) {
      results.add(new HistoryItem()..time= stopwatch.elapsedMicroseconds..line = line);
    });
  }

  void add(List<int> data) {
    lineController.add(data);
    ioSink.add(data);
  }

  void addError(error, [StackTrace stackTrace]) {
  }


  Future addStream(Stream<List<int>> stream) {
    var completer = new Completer.sync();
    stream.listen(add, onError: addError, onDone: completer.complete);
    return completer.future;
  }

  Future close() async {
    // eventually close lose command
    add('\n'.codeUnits);
    if (results.last.line.isEmpty) {
      results.removeLast();
    }
  }
}

///
/// write rest arguments as lines
///
main(List<String> arguments) async {
  //setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: false);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose', negatable: false);
  parser.addFlag(flagRunInShell, abbr: 's', help: 'RunInShell', negatable: false);
  parser.addFlag(flagStdin,
      abbr: 'i', help: 'stdin read, need CTRL-C to terminate', defaultsTo: false, negatable: true);
  parser.addOption('exit-code', abbr: 'x', help: 'Exit code to return');
  parser.addFlag('version',
      help: 'Print the command version', negatable: false);

  ArgResults _argResults = parser.parse(arguments);

  bool help = _argResults['help'];
  //bool verbose = _argResults['verbose'];
  bool runInShell = _argResults[flagRunInShell];
  bool recordStdin = _argResults[flagStdin];

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
  // Run the command
  ProcessCmd cmd = processCmd(cmdExecutable, cmdArguments, runInShell: runInShell);

  Stopwatch stopwatch = new Stopwatch();
  List<HistoryItem> cmdIn = [];

  HistorySink outSink = new HistorySink(stdout, stopwatch);
  HistorySink errSink = new HistorySink(stderr, stopwatch);



  StreamController<List<int>> stdinController = new StreamController(sync: true);
  StreamController<List<int>> stdinRecordController = new StreamController(sync: true);

  if (recordStdin) {
    stdin.listen((List<int> data) {
      stdinController.add(data);
      stdinRecordController.add(data);
    })
      ..onError((e, st) {
        stdinController.addError(e, st);
        stdinRecordController.addError(e, st);
      })
      ..onDone(() {
        stdinController.close();
        stdinRecordController.close();
      });

    stdinRecordController.stream.transform(UTF8.decoder).transform(
        new LineSplitter()).listen((String line) {
      cmdIn.add(new HistoryItem()..time = stopwatch.elapsedMicroseconds..line = line);
    });
  }

  Map record = {};

  record["date"] = new DateTime.now().toIso8601String();
  stopwatch.start();
  await runCmd(cmd, stdout: outSink, stdin: recordStdin ? stdinController.stream : null);


  await outSink.close();

  record["executable"] = cmdExecutable;
  record["arguments"] = cmdArguments;

  if ((cmdIn.length ?? 0) > 0) {
    record["in"] = cmdIn;
  }

  if (outSink.results.isNotEmpty) {
    record["out"] = outSink.results;
  }
  if (errSink.results.isNotEmpty) {
    record["err"] = errSink.results;
  }


  await new File("cmd_record.json").writeAsString(JSON.encode(record));

  /*
  // handle stdin if asked for it
  if (_argsResult['stdin']) {
    if (verbose) {
      //stderr.writeln('stdin  $stdin');
      //stderr.writeln('stdin  ${await stdin..isEmpty}');
    }
    String lineSync = stdin.readLineSync();
    if (lineSync != null) {
      stdout.write(lineSync);
    }
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
  */
}
