import 'dart:async';
import 'dart:convert';

import 'package:process_run/src/platform/platform.dart';

import 'shell_environment_common.dart';

var shellDebug = false; // devWarning(true); // false

/// The result of running a non-interactive
/// process started with [Process.run] or [Process.runSync].
class ProcessResult {
  /// Exit code for the process.
  ///
  /// See [Process.exitCode] for more information in the exit code
  /// value.
  final int exitCode;

  /// Standard output from the process. The value used for the
  /// `stdoutEncoding` argument to `Process.run` determines the type. If
  /// `null` was used, this value is of type `List<int>` otherwise it is
  /// of type `String`.
  final Object? stdout;

  /// Standard error from the process. The value used for the
  /// `stderrEncoding` argument to `Process.run` determines the type. If
  /// `null` was used, this value is of type `List<int>`
  /// otherwise it is of type `String`.
  final Object? stderr;

  /// Process id of the process.
  final int pid;

  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

class Process {}

class ProcessSignal {
  const ProcessSignal();
  static const sigterm = ProcessSignal();
}

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
abstract class Shell extends ShellCommon {
  factory Shell({ShellOptions? options, ShellEnvironment? environment}) =>
      shellContext.newShell(options: options);

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
}

abstract class ShellCommon {
  /// Create new shell at the given path
  ShellCommon cd(String path);

  /// Get the shell path, using workingDirectory or current directory if null.
  String get path;

  /// Create a new shell at the given path, allowing popd on it
  ShellCommon pushd(String path);

  /// Pop the current directory to get the previous shell
  /// throw State error if nothing in the stack
  ShellCommon popd();
}

/// Exception thrown in exitCode != 0 and throwOnError is true
class ShellException implements Exception {
  final ProcessResult? result;
  final String message;

  ShellException(this.message, this.result);

  @override
  String toString() => 'ShellException($message)';
}

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

  /// [throwOnError] means that if an exit code is not 0, it will throw an error
  ///
  /// Unless specified [runInShell] will be false. However on windows, it will
  /// default to true for non .exe files
  ///
  /// if [verbose] is not false or [commentVerbose] is true, it will display the
  /// comments as well
  const ShellOptions(
      {bool throwOnError = true,
      String? workingDirectory,
      Map<String, String>? environment,
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
        _commentVerbose = commentVerbose ?? false;

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
      bool? commentVerbose}) {
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
