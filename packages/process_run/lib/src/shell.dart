import 'dart:convert';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/import.dart';
import 'package:process_run/src/io/io.dart' as io;
import 'package:process_run/src/platform/platform.dart';

import 'package:process_run/src/process_run.dart' as impl;
import 'package:process_run/src/shell_common.dart'
    show ShellCore, ShellCoreSync, ShellOptions, shellDebug;
import 'package:process_run/src/shell_process_result.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:process_run/src/shell_utils.dart' as utils;
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
    var shell = shellContext.shell(
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
  }) async {
    var result = await runScript(
      script,
      options: ShellCommandRunOptions(onProcess: onProcess),
    );
    return result.processResults;
  }

  void _checkKilled(int runId) {
    if (_killedRunId >= runId) {
      throw ShellException.process(
        'Script was killed',
        processCmd: _currentProcessCmd,
        command: _currentProcessCmd,
      );
    }
  }

  /// Returns true for comment
  bool _handleLineComment(String command) {
    // Display the comments
    if (shellScriptLineIsComment(command)) {
      if (_options.commentVerbose) {
        stdout.writeln(command);
      }
      return true;
    }
    return false;
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
  Future<ShellProcessResults> runScript(
    String script, {
    ShellCommandRunOptions? options,
  }) {
    // devPrint('Running $script');
    return _runLocked((runId) async {
      var commands = shellScriptSplitLines(script);

      var processResults = <ShellProcessResult>[];
      for (var command in commands) {
        // Check if killed
        _checkKilled(runId);

        // Display the comments
        if (_handleLineComment(command)) {
          continue;
        }
        var shellCommand = ShellCommand.parse(command);

        var processResult = await _lockedRunCommand(
          runId,
          shellCommand,
          options: options,
        );
        processResults.add(processResult);
      }

      var result = ShellProcessResultInternalList.fromList(
        this,
        processResults,
      );
      return result;
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
    return _runScriptSync(script).processResults;
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
  ShellProcessResults _runScriptSync(String script) {
    var commands = shellScriptSplitLines(script);

    var processResults = <ShellProcessResult>[];
    for (var command in commands) {
      // Display the comments
      if (_handleLineComment(command)) {
        continue;
      }
      var shellCommand = ShellCommand.parse(command);

      var runId = ++_runId;
      var processResult = _runCommandSync(runId, shellCommand);
      processResults.add(processResult);
    }

    return ShellProcessResultInternalList.fromList(this, processResults);
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
    var command = ShellCommand(executable, arguments);
    return (await _runCommand(command)).processResult;
  }

  /// Run a single [command].
  ///
  /// Returns a process result (or throw if specified in the shell).
  ///
  /// [onProcess] is called for each started process.
  @override
  Future<ShellProcessResult> runCommand(
    ShellCommand command, {
    ShellCommandRunOptions? options,
  }) {
    return _runCommand(command, options: options);
  }

  /// Run a single [command].
  ///
  /// Returns a process result (or throw if specified in the shell).
  ///
  /// [onProcess] is called for each started process.
  Future<ShellProcessResult> _runCommand(
    ShellCommand command, {
    ShellCommandRunOptions? options,
  }) async {
    return _runLocked((runId) async {
      return (await _lockedRunCommand(runId, command, options: options));
    });
  }

  /// Run a single [command].
  ///
  /// Returns a process result (or throw if specified in the shell).
  ///
  /// [onProcess] is called for each started process.
  // ignore: unused_element
  Future<ShellProcessResults> _runCommands(
    List<ShellCommand> commands, {
    ShellCommandRunOptions? options,
  }) {
    return _runLocked((runId) async {
      var processResults = <ShellProcessResult>[];
      for (var command in commands) {
        _checkKilled(runId);
        var processResult = await _lockedRunCommand(
          runId,
          command,
          options: options,
        );
        processResults.add(processResult);
      }

      var result = ShellProcessResultInternalList.fromList(
        this,
        processResults,
      );
      return result;
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
    return (_runCommandSync(
      runId,
      ShellCommand(executable, arguments),
    )).processResult;
  }

  /// Run a single [command], resolving the [executable] if needed.
  ///
  /// Returns a process result (or throw if specified in the shell).
  ///
  /// [onProcess] is called for each started process.
  @override
  ShellProcessResult runCommandSync(ShellCommand command) {
    var runId = ++_runId;
    return _runCommandSync(runId, command);
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

  Completer<ShellProcessResult>? _currentProcessResultCompleter;

  void _clearPreviousContext() {
    if (shellDebug) {
      // ignore: avoid_print
      print(
        'Clear previous context ${_currentProcessResultCompleter?.isCompleted}',
      );
    }
    if (!(_currentProcessResultCompleter?.isCompleted ?? true)) {
      _currentProcessResultCompleter!.completeError(
        ShellException.process(
          'Killed by framework',
          command: _currentProcessCmd,
          processCmd: _currentProcessCmd,
        ),
      );
    }
    _currentProcessResultCompleter = null;
  }

  ///
  /// if [commandVerbose] or [verbose] is true, display the command.
  /// if [verbose] is true, stream stdout & stdin
  ///
  /// Compared to the async version, it is not possible to kill the spawn process nor to
  /// feed any input.
  ProcessResult _runRawExecutableArgumentsSyncImpl(
    ShellCommand command,
    ShellCommand executedCommand,
  ) {
    var verbose = options.verbose;
    var commandVerbose = options.commandVerbose;
    var stdout = options.stdout;
    var stderr = options.stderr;
    var stdoutEncoding = options.stdoutEncoding;
    var stderrEncoding = options.stderrEncoding;
    var environment = options.environment;
    var runInShell = options.runInShell;
    var workingDirectory = options.workingDirectory;

    if (verbose) {
      commandVerbose = true;
      stdout ??= io.stdout;
      stderr ??= io.stderr;
    }

    if (commandVerbose) {
      utils.streamSinkWriteln(
        stdout ?? io.stdout,
        '\$ ${command.toCommandString()}',
        encoding: stdoutEncoding,
      );
    }

    var executedCommand = _resolveExecutedCommand(command);
    var executable = executedCommand.executable;
    var arguments = executedCommand.arguments;

    // Fix runInShell on windows (force run in shell for non-.exe)
    runInShell = utils.fixRunInShell(runInShell, executable);

    io.ProcessResult result;
    try {
      result = Process.runSync(
        executable,
        arguments,
        environment: environment,
        includeParentEnvironment: false,
        runInShell: runInShell,
        workingDirectory: workingDirectory,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding,
      );
    } catch (e) {
      if (verbose) {
        impl.dumpException(
          command: executedCommand,
          exception: e,
          workingDirectory: workingDirectory,
        );
      }
      rethrow;
    }

    List<int> outputToIntList(dynamic data, Encoding? encoding) {
      if (data is List<int>) {
        return data;
      } else if (data is String && encoding != null) {
        return encoding.encode(data);
      } else {
        throw 'Unexpected data type: ${data.runtimeType}';
      }
    }

    if (stdout != null) {
      var out = outputToIntList(result.stdout, stdoutEncoding);
      stdout.add(out);
    }

    if (stderr != null) {
      var err = outputToIntList(result.stderr, stderrEncoding);
      stderr.add(err);
    }
    return result;
  }

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Call onProcess upon process startup
  ///
  /// Returns a process result (or throw if specified in the shell).
  ShellProcessResult _runCommandSync(int runId, ShellCommand command) {
    var executedCommand = _resolveExecutedCommand(command);
    var workingDirectory = _options.workingDirectory;
    try {
      _clearPreviousContext();

      ShellProcessResult? processResult;

      try {
        if (shellDebug) {
          // ignore: avoid_print
          print('$_runId: Before $command');
        }

        var rawProcessResult = _runRawExecutableArgumentsSyncImpl(
          executedCommand,
          executedCommand,
        );

        // Wrap
        processResult = wrapShellProcessResult(this, command, rawProcessResult);
      } finally {
        if (shellDebug) {
          // ignore: avoid_print
          print('$_runId: After $command exitCode ${processResult?.exitCode}');
        }
      }
      // devPrint('After $processCmd');
      if (_options.throwOnError && processResult.exitCode != 0) {
        throw ShellException.process(
          '$command, exitCode ${processResult.exitCode}, workingDirectory: ${workingDirectory ?? '.'}',
          result: processResult,
          command: command,
          processCmd: _processCmd(command, executedCommand),
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
  Check that ${executedCommand.executable} exists
    command: $command''');
      }
      writeln();

      throw ShellException.process(
        '$command, error: $e, workingDirectory: $workingDirectory',
        processCmd: _processCmd(command, executedCommand),
        command: command,
      );
    }
  }

  ///
  /// if [commandVerbose] or [verbose] is true, display the command.
  /// if [verbose] is true, stream stdout & stdin
  ///
  /// Optional [onProcess(process)] is called to allow killing the process.
  ///
  /// If [noStdoutResult] is true, the result will not contain the stdout.
  /// If [noStderrResult] is true, the result will not contain the stderr.
  ///
  /// Don't mess-up with the input and output for now here. only use it for kill.
  Future<ProcessResult> _rawRunCommandImpl(
    ShellCommand command,
    ShellCommand executedCommand, {
    ShellCommandRunOptions? options,
  }) async {
    var onProcess = options?.onProcess;
    var workingDirectory = _options.workingDirectory;
    var verbose = _options.verbose;
    var commandVerbose = _options.commandVerbose;
    var stdout = _options.stdout;
    var stderr = _options.stderr;
    var stdoutEncoding = _options.stdoutEncoding;
    var stderrEncoding = _options.stderrEncoding;
    var shellEnvironment = _options.environment;
    var runInShell = _options.runInShell;
    var stdin = _options.stdin;
    var noStdoutResult = _options.noStdoutResult;
    var noStderrResult = _options.noStderrResult;

    var mode = _options.mode;
    var noStdioOverride = <ProcessStartMode>[
      .inheritStdio,
      .detachedWithStdio,
    ].contains(mode);
    noStdoutResult ??= noStdioOverride;
    noStderrResult ??= noStdioOverride;
    if (verbose) {
      commandVerbose = true;
      stdout ??= io.stdout;
      stderr ??= io.stderr;
    }

    if (commandVerbose) {
      utils.streamSinkWriteln(
        stdout ?? io.stdout,
        '\$ ${executedCommand.toString()}',
        encoding: stdoutEncoding,
      );
    }

    var executable = executedCommand.executable;
    var arguments = executedCommand.arguments;

    // Fix runInShell on windows (force run in shell for non-.exe)
    runInShell = utils.fixRunInShell(runInShell, executable);

    Process process;
    try {
      process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: shellEnvironment,
        includeParentEnvironment: false,
        runInShell: runInShell,
        mode: mode,
      );
      if (shellDebug) {
        // ignore: avoid_print
        print('process: ${process.pid}');
      }
      if (onProcess != null) {
        onProcess(process);
      }
      if (shellDebug) {
        // ignore: unawaited_futures
        () async {
          try {
            var exitCode = await process.exitCode;
            // ignore: avoid_print
            print('process: ${process.pid} exitCode $exitCode');
          } catch (e) {
            // ignore: avoid_print
            print('process: ${process.pid} Error $e waiting exit code');
          }
        }();
      }
    } catch (e) {
      if (verbose) {
        impl.dumpException(
          command: command,
          exception: e,
          workingDirectory: workingDirectory,
        );
      }
      rethrow;
    }

    final outCtlr = StreamController<List<int>>(sync: true);
    final errCtlr = StreamController<List<int>>(sync: true);

    // Connected stdin
    // Buggy!
    StreamSubscription? stdinSubscription;
    if (stdin != null) {
      //stdin.pipe(process.stdin); // this closes the stream...
      stdinSubscription =
          stdin.listen((List<int> data) {
            process.stdin.add(data);
          })..onDone(() {
            process.stdin.close();
          });
      // OLD 2: process.stdin.addStream(stdin);
    } else {
      // Close the input sync, we want this not interractive
      //process.stdin.close();
    }

    Future<dynamic> streamToResult(
      Stream<List<int>> stream,
      Encoding? encoding,
    ) async {
      final list = <int>[];
      await for (final data in stream) {
        //devPrint('s: ${data}');
        list.addAll(data);
      }
      if (encoding != null) {
        return encoding.decode(list);
      }
      return list;
    }

    var out = (noStdoutResult)
        ? Future.value(null)
        : streamToResult(outCtlr.stream, stdoutEncoding);
    var err = (noStderrResult)
        ? Future.value(null)
        : streamToResult(errCtlr.stream, stderrEncoding);

    if (!noStdoutResult) {
      process.stdout.listen(
        (List<int> d) {
          if (stdout != null) {
            stdout.add(d);
          }
          outCtlr.add(d);
        },
        onDone: () {
          outCtlr.close();
        },
      );
    }

    if (!noStderrResult) {
      process.stderr.listen(
        (List<int> d) async {
          if (stderr != null) {
            stderr.add(d);
          }
          errCtlr.add(d);
        },
        onDone: () {
          errCtlr.close();
        },
      );
    }

    final exitCode = await process.exitCode;

    /// Cancel input sink
    if (stdinSubscription != null) {
      await stdinSubscription.cancel();
    }

    // Notice that exitCode can complete before all of the lines of output have been
    // processed. Also note that we do not explicitly close the process. In order
    // to not leak resources we have to drain both the stderr and the stdout streams.
    // To do that we set a listener (using await for) to drain the stderr stream.
    //await process.stdout.drain();
    //await process.stderr.drain();

    final result = ProcessResult(process.pid, exitCode, await out, await err);

    if (stdin != null) {
      //process.stdin.close();
    }

    // flush for consistency
    if (stdout == io.stdout) {
      await io.stdout.safeFlush();
    }
    if (stderr == io.stderr) {
      await io.stderr.safeFlush();
    }
    return result;
  }

  ProcessCmd _processCmd(ShellCommand command, ShellCommand executedCommand) =>
      _ProcessCmd(
          executedCommand.executable,
          executedCommand.arguments,
          executableShortName: command.executable,
          mode: _options.mode,
        )
        ..runInShell = _options.runInShell
        ..environment = _options.environment
        ..includeParentEnvironment = false
        ..stderrEncoding = _options.stderrEncoding
        ..stdoutEncoding = _options.stdoutEncoding
        ..workingDirectory = _options.workingDirectory;
  // Resolve the actual command ran
  ShellCommand _resolveExecutedCommand(ShellCommand command) {
    var executable = command.executable;
    var arguments = command.arguments;
    // Find alias
    var alias = _options.environment.aliases[executable];
    if (alias != null) {
      // The alias itself should be split
      var parts = shellSplit(alias);
      executable = parts[0];
      arguments = [...parts.sublist(1), ...arguments];
    }
    var executableFullPath =
        findExecutableSync(executable, _userPaths) ?? executable;

    return ShellCommand(executableFullPath, arguments);
  }

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Call onProcess upon process startup
  ///
  /// Returns a process result (or throw if specified in the shell).
  Future<ShellProcessResult> _lockedRunCommand(
    int runId,
    ShellCommand command, {
    ShellCommandRunOptions? options,
  }) {
    var onProcess = options?.onProcess;
    var runOptions = options ?? ShellCommandRunOptions();

    /// Global process handler.
    try {
      _clearPreviousContext();
      var completer = _currentProcessResultCompleter =
          Completer<ShellProcessResult>();

      Future<ShellProcessResult?> run() async {
        ShellProcessResult? processResult;

        // Find alias
        var executedCommand = _resolveExecutedCommand(command);

        var processCmd = _processCmd(command, executedCommand);
        try {
          // devPrint(_options.environment.keys.where((element) => element.contains('TEKARTIK')));
          if (shellDebug) {
            // ignore: avoid_print
            print('$_runId: Before $command');
          }

          try {
            var rawProcessResult = await _rawRunCommandImpl(
              command,
              executedCommand,
              options: runOptions.copyWith(
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
              ),
            );

            // Fix impl return value
            processResult = wrapShellProcessResult(
              this,
              command,
              rawProcessResult,
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
            throw ShellException.process(
              '$processCmd, exitCode ${processResult.exitCode}, workingDirectory: ${processCmd.workingDirectory ?? '.'}',
              result: processResult,
              processCmd: processCmd,
              command: processCmd,
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
  Check that ${executedCommand.executable} exists
    command: $processCmd''');
          }
          writeln();

          throw ShellException.process(
            '$processCmd, error: $e, workingDirectory: ${processCmd.workingDirectory ?? '.'}',
            processCmd: processCmd,
            command: processCmd,
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
    required super.mode,
    required this.executableShortName,
  });

  @override
  String toString() =>
      executableArgumentsToString(executableShortName, arguments);
}
