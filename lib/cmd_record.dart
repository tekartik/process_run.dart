#!/usr/bin/env dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

const String inPrefix = r"$";
const String outPrefix = r">";
const String errPrefix = r"E";

enum Source { IN, OUT, ERR }

class History {
  final List<HistoryItem> inItems = [];
  final List<HistoryItem> outItems = [];
  final List<HistoryItem> errItems = [];
  String executable;
  List<String> arguments;
  DateTime date;

  ProcessResult result;

  Duration duration;

  toJson() {
    Map record = {};
    record["date"] = date.toIso8601String();
    record["duration"] = duration.toString();
    record["executable"] = executable;
    record["arguments"] = arguments;

    if (inItems.isNotEmpty) {
      record["in"] = inItems;
    }

    if (outItems.isNotEmpty) {
      record["out"] = outItems;
    }
    if (errItems.isNotEmpty) {
      record["err"] = errItems;
    }
    record["exitCode"] = result.exitCode;
    return record;
  }
}

class HistoryItem {
  int time;
  String line;

  toJson() => [time, line];

  getOutput(String prefix) {
    String durationToString(Duration duration) {
      String threeDigits(int n) {
        if (n >= 100) return "$n";
        if (n >= 10) return "0$n";
        return "0$n";
      }

      String twoDigits(int n) {
        if (n >= 10) return "$n";
        return "0$n";
      }

      String twoDigitMinutes =
          twoDigits(duration.inMinutes.remainder(Duration.MINUTES_PER_HOUR));
      String twoDigitSeconds =
          twoDigits(duration.inSeconds.remainder(Duration.SECONDS_PER_MINUTE));
      String threeDigitMillis = threeDigits(
          duration.inMilliseconds.remainder(Duration.MILLISECONDS_PER_SECOND));
      return "$twoDigitMinutes:$twoDigitSeconds.$threeDigitMillis";
    }

    return "${durationToString(
        new Duration(microseconds: time))} ${prefix} ${line}";
  }
}

class HistorySink implements StreamSink<List<int>> {
  final StreamSink ioSink;

  Stream<HistoryItem> get stream => itemController.stream;

  StreamController<List<int>> lineController = new StreamController(sync: true);
  StreamController<HistoryItem> itemController =
      new StreamController(sync: true);

  final Stopwatch stopwatch;

  /// The results corresponding to events that have been added to the sink.
  // final results = <HistoryItem>[];

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
    lineController.stream
        .transform(UTF8.decoder)
        .transform(new LineSplitter())
        .listen((String line) {
      itemController.add(new HistoryItem()
        ..time = stopwatch.elapsedMicroseconds
        ..line = line);
    });
  }

  void add(List<int> data) {
    lineController.add(data);
    ioSink?.add(data);
  }

  void addError(error, [StackTrace stackTrace]) {}

  Future addStream(Stream<List<int>> stream) {
    var completer = new Completer.sync();
    stream.listen(add, onError: addError, onDone: completer.complete);
    return completer.future;
  }

  Future close() async {
    /*
    // eventually close lose command
    add('\n'.codeUnits);
    if (results.last.line.isEmpty) {
      results.removeLast();
    }
    */
    await lineController.close();
    await itemController.close();
  }
}

///
/// write rest arguments as lines
/// if history is not null
///
Future record(String executable, List<String> arguments,
    {bool runInShell,
    bool recordStdin,

    /// prevent streaming to stderr and stdout in real time
    bool noStdOutput,
    StringSink dumpSink,
    History history,
    Stream<List<int>> inStream,
    bool noStderr}) async {
  noStdOutput ??= false;
  noStderr ??= false;

  Stream<List<int>> stdinStream = inStream ?? stdin;
  // by default record if there is an incoming stream
  recordStdin ??= inStream != null;

  // Run the command
  ProcessCmd cmd = processCmd(executable, arguments, runInShell: runInShell);

  Stopwatch stopwatch = new Stopwatch();

  HistorySink outSink = new HistorySink(noStdOutput ? null : stdout, stopwatch);
  outSink.stream.listen((HistoryItem item) {
    // Output
    dumpSink?.writeln(item.getOutput(outPrefix));
    history?.outItems?.add(item);
  });
  HistorySink errSink;
  if (!noStderr) {
    HistorySink errSink =
        new HistorySink(noStdOutput ? null : stderr, stopwatch);
    errSink.stream.listen((HistoryItem item) {
      // Output
      dumpSink?.writeln(item.getOutput(errPrefix));
      history?.errItems?.add(item);
    });
  }

  StreamController<List<int>> stdinController =
      new StreamController(sync: true);
  StreamController<List<int>> stdinRecordController =
      new StreamController(sync: true);

  if (recordStdin) {
    stdinStream.listen((List<int> data) {
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

    stdinRecordController.stream
        .transform(UTF8.decoder)
        .transform(new LineSplitter())
        .listen((String line) {
      var item = new HistoryItem()
        ..time = stopwatch.elapsedMicroseconds
        ..line = line;
      // Output
      dumpSink?.writeln(item.getOutput(inPrefix));
      history?.inItems?.add(item);
    });
  }

  history?.date = new DateTime.now();
  history?.executable = executable;
  history?.arguments = arguments;

  stopwatch.start();
  ProcessResult result = await runCmd(cmd,
      stdout: outSink,
      stderr: errSink,
      stdin: recordStdin ? stdinController.stream : null);

  await outSink.close();
  await errSink?.close();
  history?.result = result;
  history?.duration = stopwatch.elapsed;
}

class _Parser {
  int index = 0;
  final List<HistoryItem> list;
  final String prefix;

  _Parser(this.prefix, this.list);

  HistoryItem get current {
    if (index == null) {
      return null;
    } else if (index >= (list?.length ?? 0)) {
      index = null;
      return null;
    }
    return list[index];
  }

  void next() {
    index++;
  }
}

dump(History history) {
  _Parser inParser = new _Parser(r'$', history.inItems);
  var parsers = [inParser];
  stdout.writeln('date ${history.date}\nduration ${history.duration}');
  stdout.writeln('\$ ${executableArgumentsToString(
          history.executable, history.arguments)}\n');

  bool done = false;
  while (!done) {
    _Parser minParser;
    int minTime;
    for (_Parser parser in parsers) {
      HistoryItem item = parser.current;
      if (item != null) {
        if ((minTime == null) || (item.time < minTime)) {
          minParser = parser;
          minTime = item.time;
        }
      }
    }

    if (minParser != null) {
      print(minParser.current.getOutput(inParser.prefix));

      /*
    }
      for (_Parser parser in parsers) {
        if (identical(parser, minParser)) {
      }
      */
      minParser.next();
    } else {
      done = true;
    }
  }
}
