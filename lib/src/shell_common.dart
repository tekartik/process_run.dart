import 'dart:async';
import 'dart:convert';

var shellDebug = false; // devWarning(true); // false

class ProcessResult {}

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
abstract class Shell {
  /// Create a new shell
  Shell clone(
      {bool? throwOnError,
      String? workingDirectory,
      // Don't change environment
      @Deprecated('Don\'t change map')
          Map<String, String>? environment,
      @Deprecated('Don\'t change includeParentEnvironment')
          // Don't change includeParentEnvironment
          bool? includeParentEnvironment,
      bool? runInShell,
      Encoding? stdoutEncoding,
      Encoding? stderrEncoding,
      Stream<List<int>>? stdin,
      StreamSink<List<int>>? stdout,
      StreamSink<List<int>>? stderr,
      bool? verbose,
      bool? commandVerbose,
      bool? commentVerbose});

  /// Create new shell at the given path
  Shell cd(String path);

  /// Get the shell path, using workingDirectory or current directory if null.
  String get path;

  /// Create a new shell at the given path, allowing popd on it
  Shell pushd(String path);

  /// Pop the current directory to get the previous shell
  /// throw State error if nothing in the stack
  Shell popd();

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

/// Exception thrown in exitCode != 0 and throwOnError is true
class ShellException implements Exception {
  final ProcessResult? result;
  final String message;

  ShellException(this.message, this.result);

  @override
  String toString() => 'ShellException($message)';
}
