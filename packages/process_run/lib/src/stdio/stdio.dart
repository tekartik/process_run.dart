import 'dart:async' as async;
import 'dart:convert';
import 'dart:core' as core;
import 'dart:core';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/import.dart';
import 'package:process_run/src/io/io.dart' as io;
import 'package:process_run/src/stdio/platform/platform.dart';

class InMemoryIOSink with IOSinkMixin implements IOSink {
  @override
  final StdioStreamType type;

  var data = <List<int>>[];
  Iterable<String> get lines =>
      LineSplitter.split(encoding.decode(data.expand((e) => e).toList()));
  InMemoryIOSink(this.type);

  @override
  void add(core.List<core.int> data) {
    this.data.add(data);
  }

  @override
  String toString() => 'InMemoryIOSink($type)';
}

mixin IOSinkMixin implements IOSink {
  bool get _isErr => type == StdioStreamType.err;
  late final IOSink ioSinkDelegate = _isErr ? ioStderr : ioStdout;
  StdioStreamType get type;
  IOSink get ioSink => ioSinkDelegate;
  @override
  Encoding get encoding => ioSink.encoding;

  @override
  void write(core.Object? object) {
    add(encoding.encode(object?.toString() ?? ''));
  }

  @override
  void writeAll(core.Iterable objects, [core.String separator = '']) {
    write(objects.join(separator));
  }

  @override
  void writeCharCode(core.int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([core.Object? object = '']) {
    write('$object\n');
  }

  @override
  set encoding(Encoding encoding) {
    throw core.UnsupportedError('ShellStdioIOSink encoding is read only');
  }

  @override
  void addError(core.Object error, [core.StackTrace? stackTrace]) {
    ioSink.addError(error, stackTrace);
  }

  @override
  async.Future addStream(async.Stream<core.List<core.int>> stream) async {
    await for (var data in stream) {
      add(data);
    }
  }

  @override
  async.Future close() async {
    await ioSink.close();
  }

  @override
  async.Future get done async {
    return ioSink.done;
  }

  @override
  async.Future flush() async {
    await ioSink.flush();
  }
}

class ShellStdioLinesGrouperIOSink with IOSinkMixin implements IOSink {
  final ShellStdioLinesGrouper grouper;
  @override
  final StdioStreamType type;
  @override
  late final IOSink ioSink;
  ShellStdioLinesGrouperIOSink(this.grouper, this.type, {IOSink? ioSink}) {
    this.ioSink = ioSink ?? super.ioSink;
  }

  @override
  void add(core.List<core.int> data) {
    var currentZoneId = _shellStdioLinesGrouper.currentZoneId;
    var zoneId = _shellStdioLinesGrouper.zoneId;

    var isCurrent = currentZoneId == zoneId;

    var streamer = _shellStdioLinesGrouper.streamers[zoneId] ??=
        ShellOutputLinesStreamer(
            current: isCurrent, stdout: grouper.stdout, stderr: grouper.stderr);
    // devPrint('[$zoneId/$currentZoneId] Adding data ${encoding.decode(data).trim()}');
    var sink = _isErr ? streamer.err : streamer.out;
    sink.add(data);
  }
}

/// Group in zones.
class ShellStdioLinesGrouper with ShellStdioMixin implements ShellStdio {
  /// Overriden mainly for testing.
  final IOSink? stdout;

  /// Overriden mainly for testing.
  final IOSink? stderr;
  int? currentZoneId;
  final streamers = <int, ShellOutputLinesStreamer>{};

  ShellStdioLinesGrouper({this.stdout, this.stderr});

  @override
  late final out =
      ShellStdioLinesGrouperIOSink(this, StdioStreamType.out, ioSink: stdout);

  @override
  late final err =
      ShellStdioLinesGrouperIOSink(this, StdioStreamType.err, ioSink: stderr);
}

final _shellStdioLinesGrouper = ShellStdioLinesGrouper();
ShellStdio get shellStdioLinesGrouper => _shellStdioLinesGrouper;

const _stdio = #tekartik_shell_stdio;
const _id = #tekartik_shell_stdio_id;

/// Shell stdio interface, default value for stdout, stderr
abstract class ShellStdio {
  /// Stdout.
  IOSink get out;

  /// Stderr.
  IOSink get err;
}

mixin ShellStdioMixin implements ShellStdio {}

int _zoneId = 0;
int _nextZoneId() => ++_zoneId;
int _inZoneCount = 0;

extension ShellStdioExt on ShellStdio {
  Future<T> runZoned<T>(Future<T> Function() action) async {
    var zoneId = _nextZoneId();
    try {
      _inZoneCount++;
      return await async
          .runZoned(action, zoneValues: {_stdio: this, _id: zoneId});
    } finally {
      _inZoneCount--;
      var streamer = _shellStdioLinesGrouper.streamers[zoneId];
      if (streamer != null) {
        await Future<void>.value(); // await streamer.done;
        streamer.close();
      }
    }
  }
}

extension ShellStdioExtPrv on ShellStdio {
  /// Only valid in a zone.
  int get zoneId => Zone.current[_id] as int;
}

/// Overriden shell stdio if any.
ShellStdio? get shellStdioOrNull =>
    _inZoneCount > 0 ? Zone.current[_stdio] as ShellStdio? : null;

/// Stream type.
enum StdioStreamType {
  /// Out
  out,

  /// Err
  err
}

/// Stdio stream line.
class StdioStreamLine {
  /// Stream type.
  final StdioStreamType type;

  /// Line.
  final String line;

  /// Stdio stream line.
  StdioStreamLine(this.type, this.line);
}

class ShellOutputLinesStreamerMemory with ShellOutputLinesStreamerMixin {
  //late final io.IOSink stdout;
  //late final io.IOSink stderr;
  ShellOutputLinesStreamerMemory(
      {bool? current = false, io.IOSink? stdout, io.IOSink? stderr}) {
    this.current = current;
  }
}

mixin ShellOutputLinesStreamerMixin implements ShellOutputLinesStreamer {
  @override
  StreamSink<List<int>> get out => outController.sink;

  @override
  StreamSink<List<int>> get err => errController.sink;

  /// Current.
  bool get current => _current ?? false;

  bool? _current;

  set current(bool? current) {
    _current = current;
  }

  /// Lines.
  var lines = <StdioStreamLine>[];

  /// Out.
  final outController = ShellLinesController();

  /// Err.
  final errController = ShellLinesController();

  void mixinDispose() {
    outController.close();
    errController.close();
  }

  @override
  Future<void> get done async {
    await Future.wait([outController.done, errController.done]);
  }

  @override
  void close() {
    mixinDispose();
  }
}

/// Stdio streamer.
abstract class ShellOutputLinesStreamer {
  /// Out stream sink
  StreamSink<List<int>> get out;

  /// Err stream sink
  StreamSink<List<int>> get err;

  /// default is io version.
  factory ShellOutputLinesStreamer(
      {bool? current = false, io.IOSink? stdout, io.IOSink? stderr}) {
    return ShellOutputLinesStreamerPlatform(
        current: current, stdout: stdout, stderr: stderr);
  }

  /// Wait for the streamer to be done.
  Future<void> get done;

  /// Close the streamer.
  void close();
}
