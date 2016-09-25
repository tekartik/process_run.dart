///
/// Command runner
///
library process_run.cmd_run;

import 'src/process_cmd.dart';
import 'process_run.dart';

export 'src/dartbin_cmd.dart';
export 'src/process_cmd.dart';
export 'process_run.dart';
export 'dartbin.dart';
export 'src/dev_cmd_run.dart';

import 'dart:io';
import 'dart:async';

///
/// Helper to run a command
///
/// Execute
Future<ProcessResult> runCmd(ProcessCmd cmd) =>
    run(cmd.executable, cmd.arguments,
        workingDirectory: cmd.workingDirectory,
        environment: cmd.environment,
        includeParentEnvironment: cmd.includeParentEnvironment,
        runInShell: cmd.runInShell,
        stdoutEncoding: cmd.stdoutEncoding,
        stderrEncoding: cmd.stderrEncoding,
        stdin: cmd.stdin,
        // ignore: deprecated_member_use
        connectStdin: cmd.connectStdin,
        connectStdout: cmd.connectStdout,
        connectStderr: cmd.connectStderr);
