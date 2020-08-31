/// {@canonicalFor prompt.prompt}
/// {@canonicalFor prompt.promptConfirm}
/// {@canonicalFor prompt.promptTerminate}
/// {@canonicalFor shell_utils.shellArgument}
/// {@canonicalFor user_config.userLoadEnv}
/// {@canonicalFor user_config.userLoadEnvFile}
/// {@canonicalFor shell_utils.platformEnvironment}
/// {@canonicalFor shell_utils.shellEnvironment}
/// {@canonicalFor shell_utils.userAppDataPath}
/// {@canonicalFor user_config.userEnvironment}
/// {@canonicalFor shell_utils.userHomePath}
/// {@canonicalFor user_config.userPaths}
library process_run.shell;

import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:process_run/src/user_config.dart';

export 'package:process_run/dartbin.dart'
    show dartVersion, dartChannel, dartExecutable;
export 'package:process_run/src/shell_utils.dart'
    show
        userHomePath,
        userAppDataPath,
        shellArgument,
        shellEnvironment,
        platformEnvironment;
export 'package:process_run/src/user_config.dart'
    show userPaths, userEnvironment, userLoadEnvFile, userLoadEnv;

export 'dartbin.dart'
    show
        getFlutterBinVersion,
        getFlutterBinChannel,
        isFlutterSupported,
        isFlutterSupportedSync;
export 'src/process_cmd.dart';
export 'src/prompt.dart' show promptConfirm, promptTerminate, prompt;

/// Exception thrown in exitCode != 0 and throwOnError is true
class ShellException implements Exception {
  final ProcessResult result;
  final String message;

  ShellException(this.message, this.result);

  @override
  String toString() => 'ShellException($message)';
}

// Simplify toString to avoid the full path got with which
class _ProcessCmd extends ProcessCmd {
  final String executableShortName;

  _ProcessCmd(String executable, List<String> arguments,
      {this.executableShortName})
      : super(executable, arguments);

  @override
  String toString() =>
      executableArgumentsToString(executableShortName, arguments);
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
class Shell {
  final bool _throwOnError;
  final String _workingDirectory;
  final Map<String, String> _environment;
  final bool _includeParentEnvironment;
  final bool _runInShell;
  final Encoding _stdoutEncoding;
  final Encoding _stderrEncoding;
  final Stream<List<int>> _stdin;
  final StreamSink<List<int>> _stdout;
  final StreamSink<List<int>> _stderr;
  final bool _verbose;
  final bool _commandVerbose;
  final bool _commentVerbose;

  /// Parent shell for pushd/popd
  Shell _parentShell;

  /// Get it only once
  List<String> _userPathsCache;

  /// Resolve environment
  List<String> get _userPaths =>
      _userPathsCache ??= getUserPaths(_environment ??
          (_includeParentEnvironment != false ? null : <String, String>{}));

  /// [throwOnError] means that if an exit code is not 0, it will throw an error
  ///
  /// Unless specified [runInShell] will be false. However on windows, it will
  /// default to true for non .exe files
  ///
  /// if [verbose] is not false or [commentVerbose] is true, it will display the
  /// comments as well
  Shell(
      {bool throwOnError = true,
      String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding,
      Stream<List<int>> stdin,
      StreamSink<List<int>> stdout,
      StreamSink<List<int>> stderr,
      bool verbose = true,
      // Default to true
      bool commandVerbose,
      // Default to false
      bool commentVerbose})
      : _throwOnError = throwOnError ?? true,
        _workingDirectory = workingDirectory,
        _environment = environment,
        _includeParentEnvironment = includeParentEnvironment ?? true,
        _runInShell = runInShell,
        _stdoutEncoding = stdoutEncoding ?? systemEncoding,
        _stderrEncoding = stderrEncoding ?? systemEncoding,
        _stdin = stdin,
        _stdout = stdout,
        _stderr = stderr,
        _verbose = verbose ?? true,
        _commandVerbose = commandVerbose ?? verbose ?? true,
        _commentVerbose = commentVerbose ?? false;

  /// Create a new shell
  Shell clone(
      {bool throwOnError,
      String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment,
      bool runInShell,
      Encoding stdoutEncoding,
      Encoding stderrEncoding,
      Stream<List<int>> stdin,
      StreamSink<List<int>> stdout,
      StreamSink<List<int>> stderr,
      bool verbose,
      bool commandVerbose,
      bool commentVerbose}) {
    return Shell(
        verbose: verbose ?? _verbose,
        environment: environment ?? _environment,
        runInShell: runInShell ?? _runInShell,
        commandVerbose: commandVerbose ?? _commandVerbose,
        commentVerbose: commentVerbose ?? _commentVerbose,
        includeParentEnvironment:
            includeParentEnvironment ?? _includeParentEnvironment,
        stderr: stderr ?? _stderr,
        stderrEncoding: stderrEncoding ?? _stderrEncoding,
        stdin: stdin ?? _stdin,
        stdout: stdout ?? _stdout,
        stdoutEncoding: stdoutEncoding ?? _stdoutEncoding,
        throwOnError: throwOnError ?? _throwOnError,
        workingDirectory: workingDirectory ?? _workingDirectory);
  }

  /// non null
  String get _workingDirectoryPath =>
      _workingDirectory ?? Directory.current.path;

  /// Create new shell at the given path
  Shell cd(String path) {
    if (isRelative(path)) {
      path = join(_workingDirectoryPath, path);
    }
    if (_commandVerbose) {
      streamSinkWriteln(_stdout ?? stdout, '\$ cd $path');
    }
    return clone(workingDirectory: path);
  }

  /// Get the shell path, using workingDurectory or current directory if null.
  String get path => _workingDirectoryPath;

  /// Create a new shell at the given path, allowing popd on it
  Shell pushd(String path) => cd(path).._parentShell = this;

  /// Pop the current directory to get the previous shell
  /// returns null if nothing in the stack
  Shell popd() {
    if (_parentShell != null && _commandVerbose) {
      stdout.writeln('\$ cd ${_parentShell._workingDirectoryPath}');
    }
    return _parentShell;
  }

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
  Future<List<ProcessResult>> run(String script) async {
    var commands = scriptToCommands(script);

    var processResults = <ProcessResult>[];
    for (var command in commands) {
      // Display the comments
      if (isLineComment(command)) {
        if (_commentVerbose) {
          stdout.writeln(command);
        }
        continue;
      }
      var parts = shellSplit(command);
      var executable = parts[0];
      var arguments = parts.sublist(1);
      var processResult = await runExecutableArguments(executable, arguments);
      processResults.add(processResult);
    }

    return processResults;
  }

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Returns a process result (or throw if specified in the shell).
  Future<ProcessResult> runExecutableArguments(
      String executable, List<String> arguments) async {
    ProcessResult processResult;
    var executableFullPath =
        findExecutableSync(executable, _userPaths) ?? executable;

    var processCmd = _ProcessCmd(executableFullPath, arguments,
        executableShortName: executable)
      ..runInShell = _runInShell
      ..environment = _environment
      ..includeParentEnvironment = _includeParentEnvironment
      ..stderrEncoding = _stderrEncoding
      ..stdoutEncoding = _stdoutEncoding
      ..workingDirectory = _workingDirectory;
    try {
      processResult = await runCmd(processCmd,
          verbose: _verbose,
          commandVerbose: _commandVerbose,
          stderr: _stderr,
          stdin: _stdin,
          stdout: _stdout);

      if (_throwOnError && processResult.exitCode != 0) {
        throw ShellException(
            '${processCmd}, exitCode ${processResult.exitCode}, workingDirectory: ${_workingDirectoryPath}',
            processResult);
      }
    } on ProcessException catch (e) {
      var stderr = _stderr ?? io.stderr;
      void _writeln([String msg]) {
        stderr.add(utf8.encode(msg ?? ''));
        stderr.add(utf8.encode('\n'));
      }

      var workingDirectory =
          processCmd.workingDirectory ?? Directory.current.path;

      _writeln();
      if (!Directory(workingDirectory).existsSync()) {
        _writeln('Missing working directory $workingDirectory');
      } else {
        _writeln('''
  Check that ${executableFullPath} exists
    command: ${processCmd}''');
      }
      _writeln();

      throw ShellException(
          '${processCmd}, error: $e, workingDirectory: ${_workingDirectoryPath}',
          null);
    }

    return processResult;
  }
}
