import 'dart:async' as async;
import 'dart:convert';
import 'dart:core' as core;
import 'dart:core';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/import.dart';
import 'package:process_run/src/io/io.dart' as io;
import 'package:process_run/src/stdio/platform/platform.dart';

// var _debugLinesGrouper = devWarning(true);
const _debugLinesGrouper = false;
var _log = print;

/// In memory implementation of [IOSink]
class InMemoryIOSink with IOSinkMixin implements IOSink {
  @override
  final StdioStreamType type;

  /// Data
  var data = <List<int>>[];

  /// Lines
  Iterable<String> get lines =>
      LineSplitter.split(encoding.decode(data.expand((e) => e).toList()));

  /// In memory implementation of [IOSink]
  InMemoryIOSink(this.type);

  @override
  void add(core.List<core.int> data) {
    this.data.add(data);
  }

  @override
  String toString() => 'InMemoryIOSink($type)';
}

/// Mixin for [IOSink]
mixin IOSinkMixin implements IOSink {
  bool get _isErr => type == StdioStreamType.err;

  /// Delegate
  late final IOSink ioSinkDelegate = _isErr ? ioStderr : ioStdout;

  /// sink type
  StdioStreamType get type;

  /// io sink
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

/// Shell stdio lines grouper implementation of [IOSink]
class ShellStdioLinesGrouperIOSink with IOSinkMixin implements IOSink {
  /// grouper
  final ShellStdioLinesGrouper grouper;
  @override
  final StdioStreamType type;
  @override
  late final IOSink ioSink;

  /// Shell stdio lines grouper implementation of [IOSink]
  ShellStdioLinesGrouperIOSink(this.grouper, this.type, {IOSink? ioSink}) {
    this.ioSink = ioSink ?? super.ioSink;
  }

  @override
  void add(core.List<core.int> data) {
    var zoneId = grouper.zoneId;
    var streamer = grouper.streamers[zoneId] ??= ShellOutputLinesStreamer(
        stdout: grouper.stdout, stderr: grouper.stderr);
    // devPrint('[$zoneId/$currentZoneId] Adding data ${encoding.decode(data).trim()}');
    var sink = _isErr ? streamer.err : streamer.out;
    sink.add(data);
  }
}

/// Global zone id.
int _zoneId = 0;
int _nextZoneId() => ++_zoneId;
int _inZoneCount = 0;

/// Group in zones.
class ShellStdioLinesGrouper with ShellStdioMixin implements ShellStdio {
  /// Overriden mainly for testing.
  final IOSink? stdout;

  /// Overriden mainly for testing.
  final IOSink? stderr;

  /// Current zone id
  int? currentZoneId;

  /// Streamers
  final streamers = <int, ShellOutputLinesStreamer>{};

  /// Ordered streamer ids
  final streamerZoneIds = <int>[];

  /// Group in zones.
  ShellStdioLinesGrouper({this.stdout, this.stderr});

  @override
  late final out =
      ShellStdioLinesGrouperIOSink(this, StdioStreamType.out, ioSink: stdout);

  @override
  late final err =
      ShellStdioLinesGrouperIOSink(this, StdioStreamType.err, ioSink: stderr);

  void _setCurrent() {
    if (_debugLinesGrouper) {
      _log('_setCurrent $currentZoneId $streamerZoneIds');
    }
    if (currentZoneId == null) {
      var firstZoneId = streamerZoneIds.firstOrNull;
      if (firstZoneId != null) {
        streamers[firstZoneId]?.current = true;
        currentZoneId = firstZoneId;
        if (_debugLinesGrouper) {
          _log('_setCurrent new $currentZoneId');
        }
      }
    }
  }

  /// Run in a zone, grouping lines
  Future<T> _runZonedImpl<T>(Future<T> Function() action) async {
    var zoneId = _nextZoneId();
    streamers[zoneId] =
        ShellOutputLinesStreamer(stdout: stdout, stderr: stderr);
    streamerZoneIds.add(zoneId);
    _setCurrent();

    try {
      _inZoneCount++;
      return await async.runZoned(() async {
        try {
          return await action();
        } finally {
          var streamer = streamers[zoneId];
          streamer?.close();
          if (currentZoneId == zoneId) {
            streamerZoneIds.remove(zoneId);
            currentZoneId = null;
          }
          _setCurrent();
        }
      }, zoneValues: {_stdio: this, _id: zoneId});
    } finally {
      _inZoneCount--;
    }
  }
}

final _shellStdioLinesGrouper = ShellStdioLinesGrouper();

/// Shell stdio lines grouper.
///
/// Use runZoned to group Shell and stdio output and error
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

/// Shell stdio mixin.
mixin ShellStdioMixin implements ShellStdio {}

/// Shell stdio extension.
extension ShellStdioExt on ShellStdio {
  /// Run in a zone, grouping lines
  Future<T> runZoned<T>(Future<T> Function() action) =>
      self._runZonedImpl(action);
}

/// Shell stdio extension private.
extension ShellStdioExtPrv on ShellStdio {
  /// Casted to private implementation.
  ShellStdioLinesGrouper get self => this as ShellStdioLinesGrouper;

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

/// Memory implementation of [ShellOutputLinesStreamer]
class ShellOutputLinesStreamerMemory with ShellOutputLinesStreamerMixin {
  /// Memory implementation of [ShellOutputLinesStreamer]
  ShellOutputLinesStreamerMemory({io.IOSink? stdout, io.IOSink? stderr});

  // No effect by default (in memory), overriden on io.
  @override
  void dump() {}
}

/// Mixin for [ShellOutputLinesStreamer]
mixin ShellOutputLinesStreamerMixin implements ShellOutputLinesStreamer {
  @override
  StreamSink<List<int>> get out => outController.sink;

  @override
  StreamSink<List<int>> get err => errController.sink;

  /// Current.
  @override
  bool get current => _current;

  var _current = false;

  @override
  set current(bool current) {
    _current = current;
  }

  /// Lines.
  var lines = <StdioStreamLine>[];

  /// Out.
  final outController = ShellLinesController();

  /// Err.
  final errController = ShellLinesController();

  /// Dispose.
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
  factory ShellOutputLinesStreamer({io.IOSink? stdout, io.IOSink? stderr}) {
    return ShellOutputLinesStreamerPlatform(stdout: stdout, stderr: stderr);
  }

  /// Get the current state.
  bool get current;

  /// Set the current state.
  set current(bool current);

  /// Wait for the streamer to be done.
  Future<void> get done;

  /// Dump existing lines.
  void dump();

  /// Close the streamer.
  void close();
}
