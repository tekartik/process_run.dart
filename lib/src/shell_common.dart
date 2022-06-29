import 'dart:async';
import 'dart:convert';

import 'package:process_run/shell.dart';
import 'package:process_run/src/platform/platform.dart';

import 'io/io_import.dart' show ProcessResult, Process, ProcessSignal;

export 'package:process_run/shell.dart'
    show Shell, ShellException, ShellEnvironment;

export 'io/io_import.dart' show ProcessResult, Process, ProcessSignal;

var shellDebug = false; // devWarning(true); // false

/// Multiplatform Shell utility to run a script with multiple commands.
///
/// Extra path/env can be loaded using ~/.config/tekartik/process_run/env.yaml
///
/// ```
/// path: ~/bin
/// ```
///
/// or
///
/// ```
/// path:
///   - ~/bin
///   - ~/Android/Sdk/tools/bin
/// env:
///   ANDROID_TOP: ~/Android
///   FIREBASE_TOP: ~/.firebase
/// ```
///
/// A list of ProcessResult is returned
///
abstract class ShellCore {
  /*
  ShellCore(
          {ShellOptions? options,
          Map<String, String>? environment,

          /// Compat, prefer options
          bool? verbose,
          Encoding? stdoutEncoding,
          Encoding? stderrEncoding,
          StreamSink<List<int>>? stdout,
          StreamSink<List<int>>? stderr,
          bool? runInShell}) =>
      shellContext.newShell(
          options: options?.clone(
              verbose: verbose,
              stderrEncoding: stderrEncoding,
              stdoutEncoding: stdoutEncoding,
              runInShell: runInShell,
              stdout: stdout,
              stderr: stderr),
          environment: environment);*/

  /// Kills the current running process.
  ///
  /// Returns `true` if the signal is successfully delivered to the process.
  /// Otherwise the signal could not be sent, usually meaning,
  /// that the process is already dead.
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);

  ///
  /// Run one or multiple plain text command(s).
  ///
  /// Commands can be splitted by line.
  ///
  /// Commands can be on multiple line if ending with ' ^' or ' \'. (note that \
  /// must be escaped too so you might have to enter \\).
  ///
  /// Returns a list of executed command line results.
  ///
  /// [onProcess] is called for each started process.
  ///
  Future<List<ProcessResult>> run(String script,
      {void Function(Process process)? onProcess});

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Returns a process result (or throw if specified in the shell).
  ///
  /// [onProcess] is called for each started process.
  Future<ProcessResult> runExecutableArguments(
      String executable, List<String> arguments,
      {void Function(Process process)? onProcess});

  /// Create new shell at the given path
  Shell cd(String path);

  /// Get the shell path, using workingDirectory or current directory if null.
  String get path;

  /// Create a new shell at the given path, allowing popd on it
  Shell pushd(String path);

  /// Pop the current directory to get the previous shell
  /// throw State error if nothing in the stack
  Shell popd();
}

/*
/// Exception thrown in exitCode != 0 and throwOnError is true
class ShellException implements Exception {
  final ProcessResult? result;
  final String message;

  ShellException(this.message, this.result);

  @override
  String toString() => 'ShellException($message)';
}
*/

class ShellOptions {
  final bool _throwOnError;
  final String? _workingDirectory;

  final bool? _runInShell;
  final Encoding? _stdoutEncoding;
  final Encoding? _stderrEncoding;
  final Stream<List<int>>? _stdin;
  final StreamSink<List<int>>? _stdout;
  final StreamSink<List<int>>? _stderr;
  final bool _verbose;
  final bool _commandVerbose;
  final bool _commentVerbose;

  late final ShellEnvironment? _environment;

  String? get workingDirectory => _workingDirectory;
  ShellEnvironment get environment => _environment!;
  StreamSink<List<int>>? get stdout => _stdout;
  StreamSink<List<int>>? get stderr => _stderr;
  Stream<List<int>>? get stdin => _stdin;
  Encoding? get stdoutEncoding => _stdoutEncoding;
  Encoding? get stderrEncoding => _stderrEncoding;

  /// [throwOnError] means that if an exit code is not 0, it will throw an error
  ///
  /// Unless specified [runInShell] will be false. However on windows, it will
  /// default to true for non .exe files
  ///
  /// if [verbose] is not false or [commentVerbose] is true, it will display the
  /// comments as well
  ShellOptions(
      {bool throwOnError = true,
      String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool? runInShell,
      Encoding? stdoutEncoding,
      Encoding? stderrEncoding,
      Stream<List<int>>? stdin,
      StreamSink<List<int>>? stdout,
      StreamSink<List<int>>? stderr,
      bool verbose = true,
      // Default to true
      bool? commandVerbose,
      // Default to false
      bool? commentVerbose})
      : _throwOnError = throwOnError,
        _workingDirectory = workingDirectory,
        _runInShell = runInShell,
        _stdoutEncoding = stdoutEncoding,
        _stderrEncoding = stderrEncoding,
        _stdin = stdin,
        _stdout = stdout,
        _stderr = stderr,
        _verbose = verbose,
        _commandVerbose = commandVerbose ?? verbose,
        _commentVerbose = commentVerbose ?? false {
    _environment = ShellEnvironment.full(
        environment: environment,
        includeParentEnvironment: includeParentEnvironment);
  }

  bool get commandVerbose => _commandVerbose;

  bool get commentVerbose => _commentVerbose;

  bool? get runInShell => _runInShell;

  bool? get verbose => _verbose;

  bool get throwOnError => _throwOnError;

  /// Create a new shell
  ShellOptions clone(
      {bool? throwOnError,
      String? workingDirectory,
      bool? runInShell,
      Encoding? stdoutEncoding,
      Encoding? stderrEncoding,
      Stream<List<int>>? stdin,
      StreamSink<List<int>>? stdout,
      StreamSink<List<int>>? stderr,
      bool? verbose,
      bool? commandVerbose,
      bool? commentVerbose,
      ShellEnvironment? shellEnvironment}) {
    return ShellOptions(
        verbose: verbose ?? _verbose,
        runInShell: runInShell ?? _runInShell,
        commandVerbose: commandVerbose ?? _commandVerbose,
        commentVerbose: commentVerbose ?? _commentVerbose,
        stderr: stderr ?? _stderr,
        stderrEncoding: stderrEncoding ?? _stderrEncoding,
        stdin: stdin ?? _stdin,
        stdout: stdout ?? _stdout,
        stdoutEncoding: stdoutEncoding ?? _stdoutEncoding,
        throwOnError: throwOnError ?? _throwOnError,
        workingDirectory: workingDirectory ?? _workingDirectory);
  }
}

/// Which common implementation
Future<String?> which(String command,
    {ShellEnvironment? environment,
    bool includeParentEnvironment = true}) async {
  return shellContext.which(command,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment);
}
