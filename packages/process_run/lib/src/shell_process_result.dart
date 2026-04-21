import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/utils/uint8list_utils.dart';

/// Shell process result
/// Replacement for io only ProcessResult with same interface
abstract class ShellProcessResult {
  /// Internal constructor.
  @internal
  factory ShellProcessResult(
    Shell shell,
    ShellCommand command,
    ProcessResult processResult,
  ) => _ShellProcessResult(shell, command, processResult);

  /// Exit code for the process.
  ///
  /// See [Process.exitCode] for more information in the exit code
  /// value.
  int get exitCode;

  /// Standard output from the process.
  ///
  /// The value used for the `stdoutEncoding` argument to [Process.run]
  /// determines the type. If `null` was used, this value is of type
  /// [Uint8List] otherwise it is of type `String`.
  Object get stdout;

  /// Standard error from the process.
  ///
  /// The value used for the `stderrEncoding` argument to [Process.run]
  /// determines the type. If `null` was used, this value is of type
  /// [Uint8List] otherwise it is of type [String].
  Object get stderr;

  /// Process id of the process.
  int get pid;
}

/// Shell process result extension
extension ProcessRunShellProcessResultExt on ShellProcessResult {
  _ShellProcessResult get _shellProcessResult => this as _ShellProcessResult;
  Shell get _shell => _shellProcessResult.shell;

  Iterable<String> _outputTextToLines(String output) =>
      LineSplitter.split(output);

  /// Process command executed
  ShellCommand get processExecutableArguments =>
      _shellProcessResult.processExecutableArguments;

  String? _outputAsText(Object output, Encoding? encoding) {
    if (output is String) {
      return output;
    } else if (output is List<int>) {
      if (output.isEmpty) {
        return '';
      }
      return (encoding ?? _shell.context.encoding).decode(output);
    }
    return null;
  }

  Uint8List? _outputAsUint8List(Object output, Encoding? encoding) {
    if (output is Uint8List) {
      return output;
    } else if (output is String) {
      if (output.isEmpty) {
        return Uint8List(0);
      }
      return asUint8List((encoding ?? _shell.context.encoding).encode(output));
    }
    return null;
  }

  /// Join the out lines for a quick string access.
  String get outText => outLines.join('\n');

  /// Join the out lines for a quick string access.
  String get errText => errLines.join('\n');

  /// Out line lists
  Iterable<String> get outLines => _outputTextToLines(stdoutAsString);

  /// Err line lists
  Iterable<String> get errLines => _outputTextToLines(stderrAsString);

  /// Out as string
  String get stdoutAsString {
    var text = _outputAsText(stdout, _shell.options.stdoutEncoding);
    if (text != null) {
      return text;
    }
    throw ArgumentError('Unsupported stdout type: ${stdout.runtimeType}');
  }

  /// Err as string
  String get stderrAsString {
    var text = _outputAsText(stderr, _shell.options.stderrEncoding);
    if (text != null) {
      return text;
    }
    throw ArgumentError('Unsupported stderr type: ${stderr.runtimeType}');
  }

  /// Out as bytes
  Uint8List get stdoutAsUint8List {
    var bytes = _outputAsUint8List(stdout, _shell.options.stdoutEncoding);
    if (bytes != null) {
      return bytes;
    }
    throw ArgumentError('Unsupported stdout type: ${stdout.runtimeType}');
  }

  /// Err as bytes
  Uint8List get stderrAsUint8List {
    var bytes = _outputAsUint8List(stderr, _shell.options.stderrEncoding);
    if (bytes != null) {
      return bytes;
    }
    throw ArgumentError('Unsupported stderr type: ${stderr.runtimeType}');
  }

  /// The original raw representation
  ProcessResult get processResult => _shellProcessResult.processResult;
}

class _ShellProcessResult implements ShellProcessResult {
  final Shell shell;
  final ProcessResult processResult;
  final ShellCommand processExecutableArguments;
  _ShellProcessResult(
    this.shell,
    this.processExecutableArguments,
    this.processResult,
  );

  @override
  int get exitCode => processResult.exitCode;

  @override
  int get pid => processResult.pid;

  /// Default to empty string
  Object _outputAsObject(dynamic output) {
    return (output as Object?) ?? '';
  }

  @override
  Object get stderr => _outputAsObject(processResult.stderr);

  @override
  Object get stdout => _outputAsObject(processResult.stdout);
}

/// Shell process results
abstract class ShellProcessResults implements List<ShellProcessResult> {}

/// Shell process results extension
extension ProcessRunShellProcessResultsPrvExt on ShellProcessResults {
  /// Get the compat precess results
  List<ProcessResult> get processResults => _impl.processResults;
}

/// Shell process results extension
extension ProcessRunShellProcessResultsExt on ShellProcessResults {
  _ShellProcessResults get _impl => this as _ShellProcessResults;

  /// The shell started the processes.
  Shell get shell => _impl.shell;

  /// Out as bytes
  Uint8List get stdoutAsUint8List {
    var builder = BytesBuilder();
    for (var result in this) {
      builder.add(result.stdoutAsUint8List);
    }
    return builder.takeBytes();
  }

  /// Err as bytes
  Uint8List get stderrAsUint8List {
    var builder = BytesBuilder();
    for (var result in this) {
      builder.add(result.stderrAsUint8List);
    }
    return builder.takeBytes();
  }

  /// Join the out lines for a quick string access.
  String get outText => outLines.join('\n');

  /// Join the out lines for a quick string access.
  String get errText => errLines.join('\n');

  /// Out line lists
  Iterable<String> get outLines => expand((result) => result.outLines);

  /// Err line lists
  Iterable<String> get errLines => expand((result) => result.errLines);

  /// Out as string
  String get stdoutAsString =>
      map((result) => result.stdoutAsString).join('\n');

  /// Err as string
  String get stderrAsString =>
      map((result) => result.stderrAsString).join('\n');
}

abstract class _ShellProcessResults implements ShellProcessResultInternalList {
  factory _ShellProcessResults.fromRawList(
    Shell shell,
    List<ProcessResult> processResults,
  ) => _ShellProcessResultsFromRaw(shell, processResults);
  factory _ShellProcessResults.fromList(
    Shell shell,
    List<ShellProcessResult> processResults,
  ) => _ShellProcessResultsFromList(shell, processResults);
}

abstract class _ShellProcessResultsBase extends ListBase<ShellProcessResult>
    implements ShellProcessResultInternalList, _ShellProcessResults {
  final Shell shell;
  final List<ShellProcessResult> _list;

  _ShellProcessResultsBase(this.shell, this._list);

  @override
  int get length => _list.length;

  @override
  set length(int newLength) => throw UnsupportedError('ReadOnly');

  @override
  ShellProcessResult operator [](int index) => _list[index];

  @override
  void operator []=(int index, ShellProcessResult value) =>
      throw UnsupportedError('ReadOnly');

  @override
  List<ProcessResult> get processResults;
}

class _ShellProcessResultsFromRaw extends _ShellProcessResultsBase
    implements _ShellProcessResults {
  _ShellProcessResultsFromRaw(Shell shell, this.processResults)
    : super(
        shell,
        List.of(
          processResults.map(
            (processResult) => processResult.unwrapShellProcessResult(),
          ),
        ),
      );

  @override
  final List<ProcessResult> processResults;
}

class _ShellProcessResultsFromList extends _ShellProcessResultsBase
    implements _ShellProcessResults {
  _ShellProcessResultsFromList(super.shell, super._list);

  /// Compat
  @override
  late final processResults = ProcessResultInternalList(
    shell,
    _list
        .map((shellProcessResult) => shellProcessResult.processResult)
        .toList(),
  );
}

/// Internal list for current run method
abstract class ProcessResultInternalList implements List<ProcessResult> {
  /// Internal list for current run method
  factory ProcessResultInternalList(
    Shell shell,
    List<ProcessResult> processResults,
  ) => _ProcessResultInternalList(shell, processResults);
}

/// Internal list for current run method
abstract class ShellProcessResultInternalList implements ShellProcessResults {
  /// from raw list
  factory ShellProcessResultInternalList.fromRawList(
    Shell shell,
    List<ProcessResult> processResults,
  ) => _ShellProcessResults.fromRawList(shell, processResults);

  /// From full list
  factory ShellProcessResultInternalList.fromList(
    Shell shell,
    List<ShellProcessResult> processResults,
  ) => _ShellProcessResults.fromList(shell, processResults);

  /// Raw process results (compat)
  List<ProcessResult> get processResults;
}

final _expando = Expando<ShellProcessResult>();

/// Needed
/// Internal
ShellProcessResult wrapShellProcessResult(
  Shell shell,
  ShellCommand processExecutableArguments,
  ProcessResult processResult,
) {
  var shellProcessResult = ShellProcessResult(
    shell,
    processExecutableArguments,
    processResult,
  );
  _expando[processResult] = shellProcessResult;
  return shellProcessResult;
}

/// Private extension
extension ProcessRunProcessResultPrvExt on ProcessResult {
  /// Internal
  ShellProcessResult unwrapShellProcessResult() {
    var shellProcessResult = unwrapShellProcessResultOrNull();
    shellProcessResult ??= ShellProcessResult(
      Shell(),
      ShellCommand.empty(),
      this,
    );
    return shellProcessResult;
  }

  /// Internal
  ShellProcessResult? unwrapShellProcessResultOrNull() {
    return _expando[this];
  }
}

/// Test extension
@visibleForTesting
extension ProcessRunProcessResultTestExt on ProcessResult {
  /// typically only true for native shell process results
  bool get isShellProcessResult {
    return unwrapShellProcessResultOrNull() != null;
  }
}

/// Internal list for current run method
extension ProcessResultInternalListExt on ProcessResultInternalList {
  _ProcessResultInternalList get _impl => this as _ProcessResultInternalList;

  /// ShellProcessResults helper
  ShellProcessResults get shellProcessResults =>
      ShellProcessResultInternalList.fromRawList(_impl.shell, this);
}

class _ProcessResultInternalList extends ListBase<ProcessResult>
    implements ProcessResultInternalList {
  final Shell shell;
  final List<ProcessResult> list;

  _ProcessResultInternalList(this.shell, this.list);

  @override
  int get length => list.length;

  @override
  set length(int newLength) => throw UnsupportedError('ReadOnly');

  @override
  ProcessResult operator [](int index) => list[index];

  @override
  void operator []=(int index, ProcessResult value) =>
      throw UnsupportedError('ReadOnly');
}
