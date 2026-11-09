@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run_test/shared_stdin/compile_shared_stdin_child.dart';
import 'package:test/test.dart';

/// Longer than the program needs, shorter than the test timeout.
const _timeout = Duration(seconds: 15);

/// The program using `sharedStdIn` on its real stdin, compiled or as a
/// `dart run` script.
void main() {
  group('sharedStdIn compiled', () {
    late String program;
    setUpAll(() async {
      program = await compileSharedStdinChild();
    });
    _sharedStdinTests(() => [program]);
  });
  group('sharedStdIn dart run', () {
    _sharedStdinTests(
      () => [
        dartExecutable!,
        'run',
        join('lib', 'shared_stdin', 'shared_stdin_child.dart'),
      ],
    );
  });
}

/// The tests running the program, [command] giving its executable then its
/// first arguments.
void _sharedStdinTests(List<String> Function() command) {
  /// Runs the program [mode] with [input] on its stdin, written once the
  /// program printed `ready` when [onReady]. Its stdin is then closed, unless
  /// [keepStdinOpen] (closed once it exited).
  ///
  /// Returns null when it did not exit within [_timeout] (it is then
  /// killed).
  Future<ProcessResult?> run(
    String mode, {
    String input = '',
    bool onReady = false,
    bool keepStdinOpen = false,
  }) async {
    var stdinController = ShellLinesController();
    var stdoutController = ShellLinesController();
    var shell = Shell(
      stdin: stdinController.binaryStream,
      stdout: stdoutController.sink,
      verbose: false,
      throwOnError: false,
    );
    var ready = Completer<void>();
    stdoutController.stream.listen((line) {
      if (line == 'ready' && !ready.isCompleted) {
        ready.complete();
      }
    });
    var executable = command();
    var done = shell.runExecutableArguments(executable.first, [
      ...executable.skip(1),
      mode,
    ]);
    try {
      if (onReady) {
        await ready.future.timeout(_timeout);
      }
      stdinController.write(input);
      if (!keepStdinOpen) {
        stdinController.close();
      }
      return await done.timeout(_timeout);
    } on TimeoutException catch (_) {
      // A killed shell throws.
      done.ignore();
      shell.kill(ProcessSignal.sigkill);
      return null;
    } finally {
      stdinController.close();
      stdoutController.close();
    }
  }

  test('lines until the end of input', () async {
    var result = await run('lines', input: 'a\nb\n');
    expect(result, isNotNull, reason: 'hangs at the end of input');
    expect(result!.outLines, ['lines: a,b', 'done']);
    expect(result.exitCode, 0);
  });

  test('command reading its input until the end', () async {
    var result = await run('shell', input: 'hello\n');
    expect(result, isNotNull, reason: 'the command never gets its end');
    expect(result!.outLines, ['out: hello', 'done']);
    expect(result.exitCode, 0);
  });

  test('terminate with a line nobody read', () async {
    var result = await run(
      'terminate',
      input: 'typed\n',
      onReady: true,
      keepStdinOpen: true,
    );
    expect(result, isNotNull, reason: 'terminate() hangs');
    expect(result!.outLines, ['ready', 'done']);
    expect(result.exitCode, 0);
  });

  test('prompt at the end of input', () async {
    var result = await run('prompt');
    expect(result, isNotNull, reason: 'prompt hangs at the end of input');
    expect(result!.outLines, ['name: no input', 'done']);
    expect(result.exitCode, 0);
  });
}
