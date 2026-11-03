@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run_test/child/compile_child.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// A started child program and its descendants.
class _Child {
  _Child(this.shell, this.process, this.pids, this.lines, this.done);

  /// The shell running it.
  final Shell shell;

  /// The child process (the root of the tree).
  final Process process;

  /// The pids of the tree from its `ready` lines, the deepest first, the root
  /// last.
  final List<int> pids;

  /// The output lines so far.
  final List<String> lines;

  /// The end of the run: its result or the exception (a killed shell throws).
  final Future<Object?> done;

  /// The pids of its descendants.
  List<int> get descendants => pids.sublist(0, pids.length - 1);
}

void main() {
  late String child;
  var shells = <Shell>[];

  setUpAll(() async {
    child = await compileChild();
  });

  tearDown(() {
    // Leftovers of a failed test.
    for (var shell in shells) {
      shell.kill(ProcessSignal.sigkill);
    }
    shells.clear();
  });

  /// Starts the child with [arguments] and waits for its [depth] descendants
  /// to be ready.
  Future<_Child> start(List<String> arguments, {int depth = 0}) async {
    var controller = ShellLinesController();
    var shell = Shell(
      stdout: controller.sink,
      verbose: false,
      throwOnError: false,
    );
    shells.add(shell);
    var lines = <String>[];
    var pids = <int>[];
    var ready = Completer<void>();
    controller.stream.listen((line) {
      lines.add(line);
      var match = RegExp(r'^ready (\d+)$').firstMatch(line);
      if (match != null) {
        pids.add(int.parse(match.group(1)!));
        if (pids.length == depth + 1 && !ready.isCompleted) {
          ready.complete();
        }
      }
    });
    var started = Completer<Process>();
    var done = shell
        .runExecutableArguments(child, [
          '--depth',
          '$depth',
          ...arguments,
        ], onProcess: started.complete)
        .then<Object?>((result) => result, onError: (Object e) => e);
    var process = await started.future;
    await ready.future.timeout(const Duration(seconds: 30));
    expect(pids.last, process.pid);
    return _Child(shell, process, pids, lines, done);
  }

  /// Waits for [pids] to exit, at most [timeout].
  Future<void> waitGone(List<int> pids, {required Duration timeout}) async {
    var stopwatch = Stopwatch()..start();
    var running = pids;
    while (true) {
      running = [
        for (var pid in running)
          if (await ShellProcesses.isRunning(pid)) pid,
      ];
      if (running.isEmpty || stopwatch.elapsed >= timeout) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(running, isEmpty);
  }

  var sigtermExitCode = childSignalExitCode(ProcessSignal.sigterm);
  var sigkillExitCode = childSignalExitCode(ProcessSignal.sigkill);

  test('compileChild: once, up to date', () async {
    // Concurrent calls, serialized: the same executable.
    expect(await Future.wait([compileChild(), compileChild()]), [child, child]);
    var result = await runExecutableArguments(child, ['--version']);
    expect(Version.parse(result.outText.trim()), childVersion);
  });

  test('exit code once waited', () async {
    var result = await runExecutableArguments(child, [
      '--wait',
      '0',
      '--exit-code',
      '3',
    ]);
    expect(result.exitCode, 3);
    expect(result.outText.trim(), 'ready ${result.pid}');
  });

  test('ready: the pids of the tree', () async {
    var started = await start([], depth: 2);
    expect(started.pids.toSet(), hasLength(3));
    // Windows adds a console host (conhost.exe) child to each of them.
    var descendants = await ShellProcesses.descendantsOf(started.process.pid);
    expect(descendants, containsAll(started.descendants));
    if (!Platform.isWindows) {
      expect(descendants, hasLength(2));
    }
    expect(
      await ShellProcesses.findByExecutable(child),
      containsAll(started.pids),
    );
    expect(
      await ShellProcesses.kill([started.process.pid], tree: true),
      isEmpty,
    );
    // No handler: killed by sigterm.
    expect(
      await started.process.exitCode,
      Platform.isWindows ? isNot(0) : sigtermExitCode,
    );
  });

  test('sigterm caught: explicit exit code', () async {
    var started = await start(['--sigterm-exit-code', '33']);
    expect(await ShellProcesses.kill([started.process.pid]), isEmpty);
    expect(await started.process.exitCode, 33);
    await started.done;
    expect(started.lines, contains('signal SIGTERM'));
  }, testOn: '!windows');

  test('Shell.kill(sigint): caught, explicit exit code', () async {
    var started = await start(['--sigint-exit-code', '34']);
    started.shell.kill(ProcessSignal.sigint);
    expect(await started.process.exitCode, 34);
  }, testOn: '!windows');

  test('Shell.kill(sigkill): cannot be caught, the tree killed', () async {
    var started = await start([
      '--sigterm-exit-code',
      '33',
      '--sigint-exit-code',
      '34',
    ], depth: 1);
    started.shell.kill(ProcessSignal.sigkill);
    expect(
      await started.process.exitCode,
      Platform.isWindows ? isNot(0) : sigkillExitCode,
    );
    expect(await started.done, isA<ShellException>());
    await waitGone(started.pids, timeout: const Duration(seconds: 3));
  });

  test('Shell.kill(): sigterm to the whole tree', () async {
    var started = await start(['--sigterm-exit-code', '33'], depth: 2);
    var stopwatch = Stopwatch()..start();
    started.shell.kill();
    expect(await started.process.exitCode, Platform.isWindows ? isNot(0) : 33);
    await waitGone(started.pids, timeout: const Duration(seconds: 3));
    // Well before the grace period.
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('Shell.kill(): sigkill after the grace period', () async {
    var started = await start(['--ignore-sigterm'], depth: 1);
    var stopwatch = Stopwatch()..start();
    started.shell.kill();
    expect(await started.process.exitCode, sigkillExitCode);
    expect(stopwatch.elapsed, greaterThanOrEqualTo(const Duration(seconds: 5)));
    await waitGone(started.pids, timeout: const Duration(seconds: 3));
    expect(started.lines, contains('signal SIGTERM'));
  }, testOn: '!windows');

  test('Shell.kill(sigterm): the command only', () async {
    var started = await start(['--sigterm-exit-code', '33'], depth: 1);
    started.shell.kill(ProcessSignal.sigterm);
    expect(await started.process.exitCode, Platform.isWindows ? isNot(0) : 33);
    // Its child, an orphan now, still runs.
    var orphan = started.descendants.single;
    expect(await ShellProcesses.isRunning(orphan), isTrue);
    expect(await ShellProcesses.kill([orphan]), isEmpty);
  });
}
