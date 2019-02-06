import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process_run/cmd_run.dart';

@deprecated
Future<ProcessResult> devRun(String executable, List<String> arguments,
        {String workingDirectory,
        Map<String, String> environment,
        bool includeParentEnvironment = true,
        bool runInShell = false,
        Encoding stdoutEncoding = SYSTEM_ENCODING,
        Encoding stderrEncoding = SYSTEM_ENCODING,
        Stream<List<int>> stdin,
        StreamSink<List<int>> stdout,
        StreamSink<List<int>> stderr,
        @deprecated bool connectStdout = false,
        @deprecated bool connectStderr = false,
        @deprecated bool connectStdin = false}) =>
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
