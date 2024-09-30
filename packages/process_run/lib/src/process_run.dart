import 'dart:convert';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/io/io.dart' as io;
import 'package:process_run/src/io/io.dart';
import 'package:process_run/src/shell.dart';
import 'package:process_run/src/shell_utils.dart' as utils;
import 'package:process_run/src/shell_utils.dart';

import 'common/import.dart';

export 'shell_utils_io.dart' show executableArgumentsToString;

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
Future<ProcessResult> runExecutableArguments(
    String executable, List<String> arguments,
    {String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool? runInShell,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
    Stream<List<int>>? stdin,
    StreamSink<List<int>>? stdout,
    StreamSink<List<int>>? stderr,
    bool? verbose,
    bool? commandVerbose,
    bool? noStdoutResult,
    bool? noStderrResult,
    void Function(Process process)? onProcess}) async {
  if (verbose == true) {
    commandVerbose = true;
    stdout ??= io.stdout;
    stderr ??= io.stderr;
  }

  if (commandVerbose == true) {
    utils.streamSinkWriteln(stdout ?? io.stdout,
        '\$ ${executableArgumentsToString(executable, arguments)}',
        encoding: stdoutEncoding);
  }

  // Build our environment
  var shellEnvironment = ShellEnvironment.full(
      environment: environment,
      includeParentEnvironment: includeParentEnvironment);

  // Default is the full command
  var executableShortName = executable;

  // Find executable if needed, i.e. if it is only a name
  if (basename(executable) == executable) {
    // Try to find it in path or use it as is
    executable = utils.findExecutableSync(executable, shellEnvironment.paths) ??
        executable;
  } else {
    // resolve locally
    executable = utils.findExecutableSync(basename(executable), [
          join(workingDirectory ?? Directory.current.path, dirname(executable))
        ]) ??
        executable;
  }

  // Fix runInShell on windows (force run in shell for non-.exe)
  runInShell = utils.fixRunInShell(runInShell, executable);

  Process process;
  try {
    process = await Process.start(executable, arguments,
        workingDirectory: workingDirectory,
        environment: shellEnvironment,
        includeParentEnvironment: false,
        runInShell: runInShell);
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
    if (verbose == true) {
      dumpException(
          executable: executableShortName,
          arguments: arguments,
          exception: e,
          workingDirectory: workingDirectory);
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
    stdinSubscription = stdin.listen((List<int> data) {
      process.stdin.add(data);
    })
      ..onDone(() {
        process.stdin.close();
      });
    // OLD 2: process.stdin.addStream(stdin);
  } else {
    // Close the input sync, we want this not interractive
    //process.stdin.close();
  }

  Future<dynamic> streamToResult(
      Stream<List<int>> stream, Encoding? encoding) async {
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

  var out = (noStdoutResult ?? false)
      ? Future.value(null)
      : streamToResult(outCtlr.stream, stdoutEncoding);
  var err = (noStderrResult ?? false)
      ? Future.value(null)
      : streamToResult(errCtlr.stream, stderrEncoding);

  process.stdout.listen((List<int> d) {
    if (stdout != null) {
      stdout.add(d);
    }
    outCtlr.add(d);
  }, onDone: () {
    outCtlr.close();
  });

  process.stderr.listen((List<int> d) async {
    if (stderr != null) {
      stderr.add(d);
    }
    errCtlr.add(d);
  }, onDone: () {
    errCtlr.close();
  });

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

///
/// if [commandVerbose] or [verbose] is true, display the command.
/// if [verbose] is true, stream stdout & stdin
///
/// Compared to the async version, it is not possible to kill the spawn process nor to
/// feed any input.
ProcessResult runExecutableArgumentsSync(
    String executable, List<String> arguments,
    {String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool? runInShell,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
    StreamSink<List<int>>? stdout,
    StreamSink<List<int>>? stderr,
    bool? verbose,
    bool? commandVerbose}) {
  if (verbose == true) {
    commandVerbose = true;
    stdout ??= io.stdout;
    stderr ??= io.stderr;
  }

  if (commandVerbose == true) {
    utils.streamSinkWriteln(stdout ?? io.stdout,
        '\$ ${executableArgumentsToString(executable, arguments)}',
        encoding: stdoutEncoding);
  }

  // Build our environment
  var shellEnvironment = ShellEnvironment.full(
      environment: environment,
      includeParentEnvironment: includeParentEnvironment);

  // Default is the full command
  var executableShortName = executable;

  // Find executable if needed, i.e. if it is only a name
  if (basename(executable) == executable) {
    // Try to find it in path or use it as is
    executable = utils.findExecutableSync(executable, shellEnvironment.paths) ??
        executable;
  } else {
    // resolve locally
    executable = utils.findExecutableSync(basename(executable), [
          join(workingDirectory ?? Directory.current.path, dirname(executable))
        ]) ??
        executable;
  }

  // Fix runInShell on windows (force run in shell for non-.exe)
  runInShell = utils.fixRunInShell(runInShell, executable);

  io.ProcessResult result;
  try {
    result = Process.runSync(
      executable,
      arguments,
      environment: shellEnvironment,
      includeParentEnvironment: false,
      runInShell: runInShell,
      workingDirectory: workingDirectory,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  } catch (e) {
    if (verbose == true) {
      dumpException(
          executable: executableShortName,
          arguments: arguments,
          exception: e,
          workingDirectory: workingDirectory);
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

/// Command runner. not exported

/// Execute a predefined ProcessCmd command
///
/// if [commandVerbose] is true, it writes the command line executed preceeded by $ to stdout. It streams
/// stdout/error if [verbose] is true.
/// [verbose] implies [commandVerbose]
///
Future<ProcessResult> processCmdRun(ProcessCmd cmd,
    {bool? verbose,
    bool? commandVerbose,
    Stream<List<int>>? stdin,
    StreamSink<List<int>>? stdout,
    StreamSink<List<int>>? stderr,
    bool? noStdoutResult,
    bool? noStderrResult,
    void Function(Process process)? onProcess}) async {
  if (verbose == true) {
    stdout ??= io.stdout;
    stderr ??= io.stderr;
    commandVerbose ??= true;
  }

  if (commandVerbose == true) {
    streamSinkWriteln(stdout ?? io.stdout, '\$ $cmd',
        encoding: cmd.stdoutEncoding);
  }

  try {
    return await runExecutableArguments(cmd.executable, cmd.arguments,
        workingDirectory: cmd.workingDirectory,
        environment: cmd.environment,
        includeParentEnvironment: cmd.includeParentEnvironment,
        runInShell: cmd.runInShell,
        stdoutEncoding: cmd.stdoutEncoding,
        stderrEncoding: cmd.stderrEncoding,
        //verbose: verbose,
        //commandVerbose: commandVerbose,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        noStdoutResult: noStdoutResult,
        noStderrResult: noStderrResult,
        onProcess: onProcess);
  } catch (e) {
    if (verbose == true) {
      dumpException(
          executable: cmd.executable,
          arguments: cmd.arguments,
          exception: e,
          workingDirectory: cmd.workingDirectory);
    }
    rethrow;
  }
}

/// Dump the exception to stderr
void dumpException(
    {required String executable,
    required List<String> arguments,
    required Object exception,
    String? workingDirectory}) {
  io.stderr.writeln(exception);
  io.stderr.writeln('\$ ${executableArgumentsToString(executable, arguments)}');
  io.stderr.writeln(
      'workingDirectory: ${normalize(absolute(workingDirectory ?? Directory.current.path))}');
}
