import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell/src/shell_utils.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/which.dart';
import 'package:yaml/yaml.dart';

export 'package:process_run/shell/src/shell_utils.dart'
    show userHomePath, userAppDataPath, shellArgument;

/// Exception thrown in exitCode != 0 and throwOnError is true
class ShellException implements Exception {
  final String message;

  ShellException(this.message);

  @override
  String toString() => 'ShellException($message)';
}

// Simplify toString to avoid the full path got with which
class _ProcessCmd extends ProcessCmd {
  _ProcessCmd(
      {String executable, List<String> arguments, String executableFullPath})
      : super(executableFullPath, arguments);

  @override
  String toString() => executableArgumentsToString(executable, arguments);
}

/// Multiplatform Shell utility to run a script with multiple commands.
///
/// Extra path can be loaded using ~/.config/tekartik/process_run/env.yaml
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

  /// [throwOnError] means that if an exit code is not 0, it will throw an error
  Shell(
      {bool throwOnError = true,
      String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding,
      Stream<List<int>> stdin,
      StreamSink<List<int>> stdout,
      StreamSink<List<int>> stderr,
      bool verbose = true,
      // Default to true
      bool commandVerbose})
      : _throwOnError = throwOnError ?? true,
        _workingDirectory = workingDirectory,
        _environment = environment,
        _includeParentEnvironment = includeParentEnvironment ?? true,
        _runInShell = runInShell ?? false,
        _stdoutEncoding = stdoutEncoding ?? systemEncoding,
        _stderrEncoding = stderrEncoding ?? systemEncoding,
        _stdin = stdin,
        _stdout = stdout,
        _stderr = stderr,
        _verbose = verbose ?? true,
        _commandVerbose = commandVerbose ?? verbose ?? true;

  /// Run on or multiple commands
  /// Commands can be splitted by line
  /// Commands can be on multiple line if ending with ' ^' or ' \'
  Future<List<ProcessResult>> run(String script) async {
    var commands = scriptToCommands(script);

    var paths = <String>[];

    try {
      // Look for any config file in ~/tekartik/process_run/env.yaml
      var userConfig = loadYaml(await File(
              join(userAppDataPath, 'tekartik', 'process_run', 'env.yaml'))
          .readAsString());

      // Handle added path
      // can be
      //
      // path:~/bin
      //
      // or
      //
      // path:
      //   - ~/bin
      //   - ~/Android/Sdk/tools/bin
      //

      var path = userConfig['path'];
      if (path is List) {
        paths.addAll(path
            .map((path) => expandPath(path.toString()))
            .toList(growable: false));
      } else if (path is String) {
        paths.add(expandPath(path.toString()));
      }
    } catch (_) {}

    var processResults = <ProcessResult>[];
    for (var command in commands) {
      var parts = shellSplit(command);
      var executable = parts[0];
      var arguments = parts.sublist(1);
      var executableFullPath = whichSync(parts[0], paths: paths) ?? executable;

      var processCmd = _ProcessCmd(
          executableFullPath: executableFullPath,
          executable: executable,
          arguments: arguments)
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
