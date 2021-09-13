import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process_run/cmd_run.dart';

@Deprecated('Dev only, verbose')
Future<ProcessResult> devRun(String executable, List<String> arguments,
        {String? workingDirectory,
        Map<String, String>? environment,
        bool includeParentEnvironment = true,
        bool runInShell = false,
        Encoding stdoutEncoding = systemEncoding,
        Encoding stderrEncoding = systemEncoding,
        Stream<List<int>>? stdin,
        StreamSink<List<int>>? stdout,
        StreamSink<List<int>>? stderr,
        @Deprecated('use stdout') bool connectStdout = false,
        @Deprecated('use stderr') bool connectStderr = false,
        @Deprecated('use stdin') bool connectStdin = false}) =>
    run(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stderrEncoding: stderrEncoding,
        stdoutEncoding: stdoutEncoding,
        stdin: stdin,
        stderr: stderr,
        stdout: stdout,
        verbose: true);
