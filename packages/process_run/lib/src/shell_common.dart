import 'dart:async';
import 'dart:convert';

import 'package:process_run/shell.dart';
import 'package:process_run/src/platform/platform.dart';
import 'package:process_run/src/shell_context_common.dart';

import 'io/io_import.dart' show ProcessResult, ProcessSignal;

/// shell debug flag (dev only)
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
  /// Commands can be on multiple line if ending with ` ^` or `` \``. (note that ``\``
  /// must be escaped too so you might have to enter ``\\``).
  ///
  /// Returns a list of executed command line results.
  ///
  /// [onProcess] is called for each started process.
  ///
  Future<List<ProcessResult>> run(
    String script, {
    ShellOnProcessCallback? onProcess,
  });

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Returns a process result (or throw if specified in the shell).
  ///
  /// [onProcess] is called for each started process.
  Future<ProcessResult> runExecutableArguments(
    String executable,
    List<String> arguments, {
    ShellOnProcessCallback? onProcess,
  });

  /// Create new shell at the given path
  Shell cd(String path);

  /// Get the shell path, using workingDirectory or current directory if null.
  String get path;

  /// Create a new shell at the given path, allowing popd on it
  Shell pushd(String path);

  /// Pop the current directory to get the previous shell
  /// throw State error if nothing in the stack
  Shell popd();

  /// override in local (default) or user settings, null means delete,
  /// [local] defaults to true.
  Future<Shell> shellVarOverride(String name, String? value, {bool? local});

  /// Clone a new shell with the given options.
  Shell cloneWithOptions(ShellOptions options);

  /// Shell options.
  ShellOptions get options;

  /// Shell context.
  ShellContext get context;
}

/// Sync version of [ShellCore].
abstract class ShellCoreSync {
  ///
  /// Run one or multiple plain text command(s).
  ///
  /// Commands can be split by line.
  ///
  /// Commands can be on multiple line if ending with ` ^` or `` \``.  (note that ``\``
  /// must be escaped too so you might have to enter ``\\``).
  ///
  /// Returns a list of executed command line results.
  ///
  /// Compared to the async version, it is not possible to kill the spawn process nor to
  /// feed any input.
  ///
  List<ProcessResult> runSync(String script);

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Returns a process result (or throw if specified in the shell).
  ///
  /// Compared to the async version, it is not possible to kill the spawn process nor to
  /// feed any input.
  ProcessResult runExecutableArgumentsSync(
    String executable,
    List<String> arguments,
  );
}

/// Shell options.
///
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
  final bool? _noStdoutResult;
  final bool? _noStderrResult;

  late final ShellEnvironment? _environment;

  /// Specified working directory (null for not specified).
  String? get workingDirectory => _workingDirectory;

  /// Full environment used (including parent environment).
  ShellEnvironment get environment => _environment!;

  /// stdout.
  StreamSink<List<int>>? get stdout => _stdout;

  /// stderr.
  StreamSink<List<int>>? get stderr => _stderr;

  /// stdin.
  Stream<List<int>>? get stdin => _stdin;

  /// stdout encoding.
  Encoding? get stdoutEncoding => _stdoutEncoding;

  /// stderr encoding.
  Encoding? get stderrEncoding => _stderrEncoding;

  /// [throwOnError] means that if an exit code is not 0, it will throw an error
  ///
  /// Unless specified [runInShell] will be false. However on windows, it will
  /// default to true for non .exe files
  ///
  /// if [verbose] is not false or [commentVerbose] is true, it will display the
  /// comments as well.
  ///
  /// If [noStdoutResult] is true, stdout will be null in the ProcessResult result
  /// of the run command (runSync will still contain it).
  ///
  /// If [noStderrResult] is true, stderr will be null in the ProcessResult result
  /// of the run command (runSync will still contain it).
  ShellOptions({
    bool throwOnError = true,
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
    bool? commentVerbose,
    // Default to false
    bool? noStdoutResult,
    // Default to false
    bool? noStderrResult,
  }) : _throwOnError = throwOnError,
       _workingDirectory = workingDirectory,
       _runInShell = runInShell,
       _stdoutEncoding = stdoutEncoding,
       _stderrEncoding = stderrEncoding,
       _stdin = stdin,
       _stdout = stdout,
       _stderr = stderr,
       _verbose = verbose,
       _commandVerbose = commandVerbose ?? verbose,
       _commentVerbose = commentVerbose ?? false,
       _noStderrResult = noStderrResult,
       _noStdoutResult = noStdoutResult {
    _environment = ShellEnvironment.full(
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
    );
  }

  /// True if commands are displayed.
  bool get commandVerbose => _commandVerbose;

  /// True if comments are displayed.
  bool get commentVerbose => _commentVerbose;

  /// True if runInShell is specified.
  bool? get runInShell => _runInShell;

  /// True if verbose is turned on.
  bool get verbose => _verbose;

  /// True if it should throw if an error occurred.
  bool get throwOnError => _throwOnError;

  /// True if ProcessResult should not contain stdout
  bool? get noStdoutResult => _noStdoutResult;

  /// True if ProcessResult should not contain stderr
  bool? get noStderrResult => _noStderrResult;

  /// Create a new shell
  ShellOptions clone({
    bool? throwOnError,
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
    bool? noStdoutResult,
    bool? noStderrResult,
    ShellEnvironment? shellEnvironment,
  }) {
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
      workingDirectory: workingDirectory ?? _workingDirectory,
      environment: shellEnvironment ?? _environment,
      noStdoutResult: noStdoutResult ?? _noStdoutResult,
      noStderrResult: noStderrResult ?? _noStderrResult,
    );
  }
}

/// Which common implementation
Future<String?> which(
  String command, {
  ShellEnvironment? environment,
  bool includeParentEnvironment = true,
}) async {
  return shellContext.which(
    command,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
  );
}

/// Default missing implementation.
mixin ShellMixin implements ShellCore, ShellCoreSync {
  @override
  late ShellContext context;

  @override
  String get path => options.workingDirectory ?? '.';

  @override
  Future<Shell> shellVarOverride(String name, String? value, {bool? local}) {
    throw UnimplementedError('shellVarOverride');
  }

  @override
  Shell cloneWithOptions(ShellOptions options) {
    var shell = context.newShell(options: options);
    return shell;
  }
}
