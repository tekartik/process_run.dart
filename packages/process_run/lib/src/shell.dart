import 'dart:convert';

import 'package:process_run/shell.dart' as impl;
import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/import.dart';
import 'package:process_run/src/io/io.dart' as io;
import 'package:process_run/src/platform/platform.dart';
import 'package:process_run/src/process_run.dart';
import 'package:process_run/src/shell_common.dart'
    show ShellCore, ShellCoreSync, ShellOptions, shellDebug;
import 'package:process_run/src/shell_utils.dart';
import 'package:synchronized/synchronized.dart';

export 'shell_common.dart' show shellDebug;

/// Shell on process callback
typedef ShellOnProcessCallback = void Function(Process process);

///
/// Run one or multiple plain text command(s).
///
/// Commands can be split by line.
///
/// Commands can be on multiple line if ending with ` ^` or `` \``.
///
/// Returns a list of executed command line results. Verbose by default.
///
/// Prefer using [options] than the parameters. [options] overrides all other
/// parameters but [onProcess].
///
/// ```dart
/// await run('flutter build');
/// await run('dart --version');
/// await run('''
///  dart --version
///  git status
/// ''');
/// ```
Future<List<ProcessResult>> run(
  String script, {
  bool throwOnError = true,
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool? runInShell,
  Encoding stdoutEncoding = systemEncoding,
  Encoding stderrEncoding = systemEncoding,
  Stream<List<int>>? stdin,
  StreamSink<List<int>>? stdout,
  StreamSink<List<int>>? stderr,
  bool verbose = true,

  // Default to true
  bool? commandVerbose,
  // Default to true if verbose is true
  bool? commentVerbose,
  ShellOptions? options,
  ShellOnProcessCallback? onProcess,
}) {
  return Shell(
    throwOnError: throwOnError,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    stdoutEncoding: stdoutEncoding,
    stderrEncoding: stderrEncoding,
    stdin: stdin,
    stdout: stdout,
    stderr: stderr,
    verbose: verbose,
    commandVerbose: commandVerbose,
    commentVerbose: commentVerbose,
    options: options,
  ).run(script, onProcess: onProcess);
}

///
/// Run one or multiple plain text command(s).
///
/// Commands can be split by line.
///
/// Commands can be on multiple line if ending with ` ^` or `` \``.
///
/// Returns a list of executed command line results. Verbose by default.
///
///
/// ```dart
/// runSync('flutter build');
/// runSync('dart --version');
/// runSync('''
///  dart --version
///  git status
/// ''');
/// ```
///
/// Compared to the async version, it is not possible to kill the spawn process nor to
/// feed any input.
List<ProcessResult> runSync(
  String script, {
  bool throwOnError = true,
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool? runInShell,
  Encoding stdoutEncoding = systemEncoding,
  Encoding stderrEncoding = systemEncoding,
  StreamSink<List<int>>? stdout,
  StreamSink<List<int>>? stderr,
  bool verbose = true,

  // Default to true
  bool? commandVerbose,
  // Default to true if verbose is true
  bool? commentVerbose,

  /// Override all other options parameters
  ShellOptions? options,
}) {
  return Shell(
    throwOnError: throwOnError,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    stdoutEncoding: stdoutEncoding,
    stderrEncoding: stderrEncoding,
    stdin: stdin,
    stdout: stdout,
    stderr: stderr,
    verbose: verbose,
    commandVerbose: commandVerbose,
    commentVerbose: commentVerbose,
    options: options,
  ).runSync(script);
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
abstract class Shell implements ShellCore, ShellCoreSync {
  final ShellOptions _options;

  /// Incremental internal runId
  var _runId = 0;

  /// Killed runId. would kill any process with a lower run id
  var _killedRunId = 0;

  /// Current kill process signal
  late ProcessSignal _killedProcessSignal;

  /// Current child process running.
  Process? _currentProcess;

  ProcessCmd? _currentProcessCmd;
  int? _currentProcessRunId;

  /// Parent shell for pushd/popd
  Shell? _parentShell;

  /// Get it only once
  List<String>? _userPathsCache;

  /// Resolve environment
  List<String> get _userPaths =>
      _userPathsCache ??= List.from(_options.environment.paths);

  /// [throwOnError] means that if an exit code is not 0, it will throw an error
  ///
  /// Unless specified [runInShell] will be false. However on windows, it will
  /// default to true for non .exe files
  ///
  /// if [verbose] is not false or [commentVerbose] is true, it will display the
  /// comments as well
  ///
  /// [options] overrides all other parameters
  factory Shell({
    bool throwOnError = true,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool? runInShell,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
    Stream<List<int>>? stdin,
    StreamSink<List<int>>? stdout,
    StreamSink<List<int>>? stderr,
    bool verbose = true,
    // Default to true
    bool? commandVerbose,
    // Default to false
    bool? commentVerbose,

    /// Overrides all parameters
    ShellOptions? options,
  }) {
    var shell = shellContext.newShell(
      options:
          options ??
          ShellOptions(
            verbose: verbose,
            stdin: stdin,
            stdout: stdout,
            stderr: stderr,
            throwOnError: throwOnError,
            workingDirectory: workingDirectory,
            runInShell: runInShell,
            commandVerbose: commandVerbose ?? verbose,
            environment: environment,
            includeParentEnvironment: includeParentEnvironment,
            commentVerbose: commentVerbose ?? false,
            stderrEncoding: stderrEncoding,
            stdoutEncoding: stdoutEncoding,
          ),
    );
    return shell;
  }

  /// Internal use only.
  @protected
  Shell.implWithOptions(ShellOptions options) : _options = options;

  /// Shell options.
  @override
  ShellOptions get options => _options;

  /// non null
  String get _workingDirectoryPath =>
      _options.workingDirectory ?? Directory.current.path;

  /// Create new shell at the given path
  @override
  Shell cd(String path) {
    if (context.path.isRelative(path)) {
      path = context.path.join(_workingDirectoryPath, path);
    }
    if (_options.commandVerbose) {
      streamSinkWriteln(
        _options.stdout ?? stdout,
        '\$ cd $path',
        encoding: _options.stdoutEncoding,
      );
    }
    return cloneWithOptions(options.clone(workingDirectory: path));
  }

  /// Get the shell path, using workingDirectory or current directory if null.
  @override
  String get path => _workingDirectoryPath;

  /// Create a new shell at the given path, allowing popd on it
  @override
  Shell pushd(String path) => cd(path).._parentShell = this;

  /// Pop the current directory to get the previous shell
  /// throw State error if nothing in the stack
  @override
  Shell popd() {
    if (_parentShell == null) {
      throw StateError('no previous shell');
    }
    if (_options.commandVerbose) {
      stdout.writeln('\$ cd ${_parentShell!._workingDirectoryPath}');
    }
    return _parentShell!;
  }

  /// Kills the current running process.
  ///
  /// Returns `true` if the signal is successfully delivered to the process.
  /// Otherwise the signal could not be sent, usually meaning,
  /// that the process is already dead.
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    // Picked the current 'timestamp' of the run killed
    _killedRunId = _runId;
    _killedProcessSignal = signal;
    return _kill();
  }

  bool _kill() {
    if (_currentProcess != null) {
      bool result;
      try {
        io.stderr.writeln(
          'killing $_killedRunId, ${_currentProcessToString()} signal $_killedProcessSignal',
        );

        if (_killedProcessSignal == ProcessSignal.sigkill) {
          var pid = _currentProcess!.pid;

          /// Workaround when using sigkill to kill the children processes too
          if (io.Platform.isLinux || io.Platform.isMacOS) {
            try {
              /// Kill the children
              runExecutableArgumentsSync('pkill', ['-P', '$pid']);
            } catch (_) {}
          } else if (io.Platform.isWindows) {
            try {
              /// Kill the children
              // Kill children process
              // /pid <processID>	Specifies the process ID of the process to be terminated.
              // /f	Specifies that processes be forcefully ended. This parameter is ignored for remote processes; all remote processes are forcefully ended.
              // /t	Ends the specified process and any child processes started by it.
              runExecutableArgumentsSync('taskkill', [
                '/t',
                '/f',
                '/pid',
                '$pid',
              ]);
            } catch (_) {}
          }
        }

        try {
          /// kill the parent process
          result = _currentProcess!.kill(_killedProcessSignal);
        } catch (_) {
          result = false;
        }
        _clearPreviousContext();
      } catch (_) {
        result = false;
      }
      return result;
    } else if (_currentProcessResultCompleter != null) {
      _clearPreviousContext();
      return false;
    } else {
      io.stderr.writeln('Killing $_killedRunId');
      return false;
    }
  }

  ///
  /// Run one or multiple plain text command(s).
  ///
  /// Commands can be split by line.
  ///
  /// Commands can be on multiple line if ending with ` ^` or `` \``.
  ///
  /// Returns a list of executed command line results.
  ///
  /// [onProcess] is called for each started process.
  ///
  @override
  Future<List<ProcessResult>> run(
    String script, {
    ShellOnProcessCallback? onProcess,
  }) {
    // devPrint('Running $script');
    return _runLocked((runId) async {
      var commands = scriptToCommands(script);

      var processResults = <ProcessResult>[];
      for (var command in commands) {
        if (_killedRunId >= runId) {
          throw ShellException('Script was killed', null);
        }
        // Display the comments
        if (isLineComment(command!)) {
          if (_options.commentVerbose) {
            stdout.writeln(command);
          }
          continue;
        }
        var parts = shellSplit(command);
        var executable = parts[0];
        var arguments = parts.sublist(1);

        // Find alias
        var alias = _options.environment.aliases[executable];
        if (alias != null) {
          // The alias itself should be split
          parts = shellSplit(alias);
          executable = parts[0];
          arguments = [...parts.sublist(1), ...arguments];
        }
        var processResult = await _lockedRunExecutableArguments(
          runId,
          executable,
          arguments,
          onProcess: onProcess,
        );
        processResults.add(processResult);
      }

      return processResults;
    });
  }

  ///
  /// Run one or multiple plain text command(s).
  ///
  /// Commands can be split by line.
  ///
  /// Commands can be on multiple line if ending with ` ^` or `` \``.
  ///
  /// Returns a list of executed command line results.
  ///
  /// Compare to the async version, it is not possible to kill the spawn process nor to
  /// feed any input.
  ///
  @override
  List<ProcessResult> runSync(String script) {
    var commands = scriptToCommands(script);

    var processResults = <ProcessResult>[];
    for (var command in commands) {
      // Display the comments
      if (isLineComment(command!)) {
        if (_options.commentVerbose) {
          stdout.writeln(command);
        }
        continue;
      }
      var parts = shellSplit(command);
      var executable = parts[0];
      var arguments = parts.sublist(1);

      // Find alias
      var alias = _options.environment.aliases[executable];
      if (alias != null) {
        // The alias itself should be split
        parts = shellSplit(alias);
        executable = parts[0];
        arguments = [...parts.sublist(1), ...arguments];
      }
      var processResult = runExecutableArgumentsSync(executable, arguments);
      processResults.add(processResult);
    }

    return processResults;
  }

  final _runLock = Lock();

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Returns a process result (or throw if specified in the shell).
  ///
  /// [onProcess] is called for each started process.
  @override
  Future<ProcessResult> runExecutableArguments(
    String executable,
    List<String> arguments, {
    ShellOnProcessCallback? onProcess,
  }) async {
    return _runLocked((runId) async {
      return _lockedRunExecutableArguments(
        runId,
        executable,
        arguments,
        onProcess: onProcess,
      );
    });
  }

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Returns a process result (or throw if specified in the shell).
  ///
  /// [onProcess] is called for each started process.
  @override
  ProcessResult runExecutableArgumentsSync(
    String executable,
    List<String> arguments,
  ) {
    var runId = ++_runId;
    return _runExecutableArgumentsSync(runId, executable, arguments);
  }

  Future<T> _runLocked<T>(FutureOr<T> Function(int runId) action) {
    // devPrint('Previous: ${_currentProcessToString()}');
    var runId = ++_runId;
    return _runLock.synchronized(() async {
      // devPrint('Running $runId');
      return action(runId);
    });
  }

  String _currentProcessToString() {
    return 'runId:$_currentProcessRunId${_currentProcess == null ? '' : ', process: ${_currentProcess?.pid}: $_currentProcessRunId $_currentProcessCmd'}';
  }

  Completer<ProcessResult>? _currentProcessResultCompleter;

  void _clearPreviousContext() {
    if (shellDebug) {
      // ignore: avoid_print
      print(
        'Clear previous context ${_currentProcessResultCompleter?.isCompleted}',
      );
    }
    if (!(_currentProcessResultCompleter?.isCompleted ?? true)) {
      _currentProcessResultCompleter!.completeError(
        ShellException('Killed by framework', null),
      );
    }
    _currentProcessResultCompleter = null;
  }

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Call onProcess upon process startup
  ///
  /// Returns a process result (or throw if specified in the shell).
  ProcessResult _runExecutableArgumentsSync(
    int runId,
    String executable,
    List<String> arguments,
  ) {
    var executableFullPath =
        findExecutableSync(executable, _userPaths) ?? executable;
    var processCmd = ProcessCmd(executableFullPath, arguments);
    try {
      _clearPreviousContext();

      ProcessResult? processResult;

      try {
        if (shellDebug) {
          // ignore: avoid_print
          print('$_runId: Before $processCmd');
        }

        processResult = impl.runExecutableArgumentsSync(
          executableFullPath,
          arguments,
          runInShell: _options.runInShell,
          environment: _options.environment,
          includeParentEnvironment: false,
          stderrEncoding: _options.stderrEncoding ?? io.systemEncoding,
          stdoutEncoding: _options.stdoutEncoding ?? io.systemEncoding,
          workingDirectory: _options.workingDirectory,
        );
      } finally {
        if (shellDebug) {
          // ignore: avoid_print
          print(
            '$_runId: After $executableFullPath exitCode ${processResult?.exitCode}',
          );
        }
      }
      // devPrint('After $processCmd');
      if (_options.throwOnError && processResult.exitCode != 0) {
        throw ShellException(
          '$processCmd, exitCode ${processResult.exitCode}, workingDirectory: $_workingDirectoryPath',
          processResult,
        );
      }
      return processResult;
    } on ProcessException catch (e) {
      var stderr = _options.stderr ?? io.stderr;
      void writeln([String? msg]) {
        stderr.add(utf8.encode(msg ?? ''));
        stderr.add(utf8.encode('\n'));
      }

      var workingDirectory =
          _options.workingDirectory ?? Directory.current.path;

      writeln();
      if (!Directory(workingDirectory).existsSync()) {
        writeln('Missing working directory $workingDirectory');
      } else {
        writeln('''
  Check that $executableFullPath exists
    command: $processCmd''');
      }
      writeln();

      throw ShellException(
        '$processCmd, error: $e, workingDirectory: $_workingDirectoryPath',
        null,
      );
    }
  }

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Call onProcess upon process startup
  ///
  /// Returns a process result (or throw if specified in the shell).
  Future<ProcessResult> _lockedRunExecutableArguments(
    int runId,
    String executable,
    List<String> arguments, {
    ShellOnProcessCallback? onProcess,
  }) {
    /// Global process handler.
    try {
      _clearPreviousContext();
      var completer =
          _currentProcessResultCompleter = Completer<ProcessResult>();

      Future<ProcessResult?> run() async {
        ProcessResult? processResult;

        var executableFullPath =
            findExecutableSync(executable, _userPaths) ?? executable;

        var processCmd =
            _ProcessCmd(
                executableFullPath,
                arguments,
                executableShortName: executable,
              )
              ..runInShell = _options.runInShell
              ..environment = _options.environment
              ..includeParentEnvironment = false
              ..stderrEncoding = _options.stderrEncoding ?? io.systemEncoding
              ..stdoutEncoding = _options.stdoutEncoding ?? io.systemEncoding
              ..workingDirectory = _options.workingDirectory;
        try {
          // devPrint(_options.environment.keys.where((element) => element.contains('TEKARTIK')));
          if (shellDebug) {
            // ignore: avoid_print
            print('$_runId: Before $processCmd');
          }

          try {
            processResult = await processCmdRun(
              processCmd,
              verbose: _options.verbose,
              commandVerbose: _options.commandVerbose,
              stderr: _options.stderr,
              stdin: _options.stdin,
              stdout: _options.stdout,
              noStdoutResult: _options.noStdoutResult,
              noStderrResult: _options.noStderrResult,
              onProcess: (process) {
                _currentProcess = process;
                _currentProcessCmd = processCmd;
                _currentProcessRunId = runId;
                if (shellDebug) {
                  // ignore: avoid_print
                  print('onProcess ${_currentProcessToString()}');
                }
                if (onProcess != null) {
                  onProcess(process);
                }
                if (_killedRunId >= _runId) {
                  if (shellDebug) {
                    // ignore: avoid_print
                    print('shell was killed');
                  }
                  _kill();
                  return;
                }
              },
            );
          } finally {
            if (shellDebug) {
              // ignore: avoid_print
              print(
                '$_runId: After $processCmd exitCode ${processResult?.exitCode}',
              );
            }
          }
          // devPrint('After $processCmd');
          if (_options.throwOnError && processResult.exitCode != 0) {
            throw ShellException(
              '$processCmd, exitCode ${processResult.exitCode}, workingDirectory: $_workingDirectoryPath',
              processResult,
            );
          }
        } on ProcessException catch (e) {
          var stderr = _options.stderr ?? io.stderr;
          void writeln([String? msg]) {
            stderr.add(utf8.encode(msg ?? ''));
            stderr.add(utf8.encode('\n'));
          }

          var workingDirectory =
              processCmd.workingDirectory ?? Directory.current.path;

          writeln();
          if (!Directory(workingDirectory).existsSync()) {
            writeln('Missing working directory $workingDirectory');
          } else {
            writeln('''
  Check that $executableFullPath exists
    command: $processCmd''');
          }
          writeln();

          throw ShellException(
            '$processCmd, error: $e, workingDirectory: $_workingDirectoryPath',
            null,
          );
        }

        return processResult;
      }

      run()
          .then((value) {
            if (shellDebug) {
              // ignore: avoid_print
              print('$runId: done');
            }
            if (!completer.isCompleted) {
              completer.complete(value);
            }
          })
          .catchError((Object e) {
            if (shellDebug) {
              // ignore: avoid_print
              print('$runId: error $e');
            }
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          });
      return completer.future;
    } finally {
      _currentProcess = null;
    }
  }
}

// Simplify toString to avoid the full path got with which
class _ProcessCmd extends ProcessCmd {
  final String executableShortName;

  _ProcessCmd(
    super.executable,
    super.arguments, {
    required this.executableShortName,
  });

  @override
  String toString() =>
      executableArgumentsToString(executableShortName, arguments);
}

/// Exception thrown in exitCode != 0 and throwOnError is true
class ShellException implements Exception {
  /// Process result
  final ProcessResult? result;

  /// Exception message
  final String message;

  /// Shell exception
  ShellException(this.message, this.result);

  @override
  String toString() => 'ShellException($message)';
}
