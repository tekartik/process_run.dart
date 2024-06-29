import 'dart:async' as async;
import 'dart:convert';
import 'dart:core' as core;
import 'dart:core';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/import.dart';
import 'package:process_run/src/stdio/platform/platform.dart';

class ShellStdioLinesGrouperIOSink implements IOSink {
  bool get _isErr => type == StdioStreamType.err;
  late final IOSink ioSink = _isErr ? ioStderr : ioStdout;
  final StdioStreamType type;

  @override
  Encoding get encoding => ioSink.encoding;

  ShellStdioLinesGrouperIOSink(this.type);

  @override
  void add(core.List<core.int> data) {
    var currentZoneId = _shellStdioLinesGrouper.currentZoneId;
    var zoneId = _shellStdioLinesGrouper.zoneId;

    var isCurrent = currentZoneId == zoneId;

    var streamer = _shellStdioLinesGrouper.streamers[zoneId] ??=
        ShellOutputLinesStreamerPlatform(current: isCurrent);
    // devPrint('[$zoneId/$currentZoneId] Adding data ${encoding.decode(data).trim()}');
    var sink = _isErr ? streamer.err : streamer.out;
    sink.add(data);
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
    // await ioSink.flush();
  }

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
}

/// Group in zones.
class _ShellStdioLinesGrouper with ShellStdioMixin implements ShellStdio {
  int? currentZoneId;
  final streamers = <int, ShellOutputLinesStreamer>{};

  @override
  late final out = ShellStdioLinesGrouperIOSink(StdioStreamType.out);

  @override
  late final err = ShellStdioLinesGrouperIOSink(StdioStreamType.err);
}

final _shellStdioLinesGrouper = _ShellStdioLinesGrouper();
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
      streamer?.close();
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
  ShellOutputLinesStreamerMemory({bool? current = false}) {
    this.current = current;
  }
}

mixin ShellOutputLinesStreamerMixin implements ShellOutputLinesStreamer {
  @override
  StreamSink<List<int>> get err => outController.sink;

  @override
  StreamSink<List<int>> get out => outController.sink;

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
  factory ShellOutputLinesStreamer({bool? current = false}) {
    return ShellOutputLinesStreamerPlatform(current: current);
  }

  /// Close the streamer.
  void close();
}
