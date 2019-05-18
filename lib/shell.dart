import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/shell_utils.dart';

export 'package:process_run/src/shell_utils.dart'
    show userHomePath, userAppDataPath, shellArgument, shellEnvironment;
export 'package:process_run/src/user_config.dart'
    show userPaths, userEnvironment;

/// Exception thrown in exitCode != 0 and throwOnError is true
class ShellException implements Exception {
  final String message;

  ShellException(this.message);

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
      _userPathsCache ??= getEnvironmentPaths(_environment ??
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
      // Default to true if verbose is true
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
        _commentVerbose = commentVerbose ?? (verbose != false);

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
      bool commandVerbose}) {
    return Shell(
        verbose: verbose ?? _verbose,
        environment: environment ?? _environment,
        runInShell: runInShell ?? _runInShell,
        commandVerbose: commandVerbose ?? _commandVerbose,
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

  /// Create a new shell pushing a new path

  /// Run on or multiple commands
  /// Commands can be splitted by line
  /// Commands can be on multiple line if ending with ' ^' or ' \'
  Future<List<ProcessResult>> run(String script) async {
    var commands = scriptToCommands(script);

    var processResults = <ProcessResult>[];
    for (var command in commands) {
      // Display the comments
      if (command.startsWith('#')) {
        if (_commentVerbose) {
          stdout.writeln(command);
        }
        continue;
      }
      var parts = shellSplit(command);
      var executable = parts[0];
      var arguments = parts.sublist(1);
      var executableFullPath =
          findExecutableSync(command, _userPaths) ?? executable;

      var processCmd = _ProcessCmd(executableFullPath, arguments,
          executableShortName: executable)
        ..runInShell = _runInShell
        ..environment = _environment
        ..includeParentEnvironment = _includeParentEnvironment
        ..stderrEncoding = _stderrEncoding
        ..stdoutEncoding = _stdoutEncoding
        ..workingDirectory = _workingDirectory;
      try {
        var processResult = await runCmd(processCmd,
            verbose: _verbose,
            commandVerbose: _commandVerbose,
            stderr: _stderr,
            stdin: _stdin,
            stdout: _stdout);
        processResults.add(processResult);
        if (_throwOnError && processResult.exitCode != 0) {
          throw ShellException(
              '${processCmd} exitCode ${processResult.exitCode}');
        }
      } on ProcessException catch (e) {
        var stderr = _stderr ?? io.stderr;
        void _writeln([String msg]) {
          stderr.add(utf8.encode(msg ?? ''));
          stderr.add(utf8.encode('\n'));
        }

        _writeln();
        _writeln('''
  Check that ${executableFullPath} exists
    command: ${processCmd}''');
        _writeln();

        throw ShellException(e?.toString());
      }
    }

    return processResults;
  }
}
