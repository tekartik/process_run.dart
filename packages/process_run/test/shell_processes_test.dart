@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:process_run/src/shell_processes.dart';
import 'package:test/test.dart';

/// A program sleeping a minute, after starting a copy of itself when its
/// first argument (the depth) is above 0; `--ignore-sigterm` ignores sigterm.
const _sleeperSource = '''
import 'dart:async';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  var depth = arguments.isEmpty ? 0 : int.parse(arguments.first);
  var ignoreSigterm = arguments.contains('--ignore-sigterm');
  if (ignoreSigterm) {
    ProcessSignal.sigterm.watch().listen((_) {});
  }
  if (depth > 0) {
    await Process.start(Platform.resolvedExecutable, [
      '\${depth - 1}',
      if (ignoreSigterm) '--ignore-sigterm',
    ]);
  }
  await Future<void>.delayed(const Duration(minutes: 1));
}
''';

void main() {
  group('parse', () {
    test('parseLinuxProcStat', () {
      expect(parseLinuxProcStat('1234 (my app) S 1 1234 1234 0 -1'), (
        state: 'S',
        ppid: 1,
      ));
      // The name may hold spaces and parentheses.
      expect(parseLinuxProcStat('12 (a (b) c) Z 7 12'), (state: 'Z', ppid: 7));
      expect(parseLinuxProcStat('12 (name'), isNull);
      expect(parseLinuxProcStat(''), isNull);
    });

    test('linuxProcExePath', () {
      expect(linuxProcExePath('/app/my_app'), '/app/my_app');
      expect(linuxProcExePath('/app/my_app (deleted)'), '/app/my_app');
    });

    test('parsePsProcessTable', () {
      var entries = parsePsProcessTable('''
    1     0 Ss   /sbin/launchd
  123     1 S    /app/my_app --ci .
  124   123 Z    (my_app)
  125   123 R+   /app/my app/run
''');
      expect(entries.map((entry) => entry.pid), [1, 123, 125]);
      expect(entries[1].ppid, 1);
      expect(entries[1].command, '/app/my_app --ci .');
      expect(entries[2].command, '/app/my app/run');
      expect(entries[1].executable, isNull);
    });

    test('parseWindowsProcessTable', () {
      var entries = parseWindowsProcessTable(
        '4|0|0|\r\n'
        r'120|4|133000000000000000|C:\app\my_app.exe'
        '\r\n'
        'bad line\r\n',
      );
      expect(entries.map((entry) => entry.pid), [4, 120]);
      expect(entries[0].executable, isNull);
      expect(entries[1].ppid, 4);
      expect(entries[1].created, 133000000000000000);
      expect(entries[1].executable, r'C:\app\my_app.exe');
    });

    test('processTableDescendantIds', () {
      var table = [
        ProcessTableEntry(pid: 1, ppid: 0),
        ProcessTableEntry(pid: 10, ppid: 1),
        ProcessTableEntry(pid: 11, ppid: 10),
        ProcessTableEntry(pid: 12, ppid: 10),
        ProcessTableEntry(pid: 13, ppid: 11),
        ProcessTableEntry(pid: 20, ppid: 1),
      ];
      expect(processTableDescendantIds(table, [10]), [11, 12, 13]);
      expect(processTableDescendantIds(table, [13]), isEmpty);
      expect(processTableDescendantIds(table, [11, 20]), [13]);
      expect(processTableDescendantIds(table, [99]), isEmpty);
      // Windows: an orphan keeps the pid of its dead parent, reused since by
      // a newer process: not its child.
      var windowsTable = [
        ProcessTableEntry(pid: 10, ppid: 1, created: 200),
        ProcessTableEntry(pid: 11, ppid: 10, created: 100),
        ProcessTableEntry(pid: 12, ppid: 10, created: 300),
      ];
      expect(processTableDescendantIds(windowsTable, [10]), [12]);
    });
  });

  group('processes', () {
    late Directory dir;
    late Shell shell;
    var index = 0;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('shell_processes_test');
      shell = Shell(
        workingDirectory: dir.path,
        verbose: false,
        throwOnError: false,
      );
    });

    tearDown(() async {
      shell.kill(ProcessSignal.sigkill);
      try {
        await dir.delete(recursive: true);
      } catch (_) {
        // Windows: an executable still running.
      }
    });

    /// A compiled sleeper, its own executable per test (its processes are
    /// found by their executable).
    Future<String> compileSleeper() async {
      var source = File(p.join(dir.path, 'sleeper.dart'));
      await source.writeAsString(_sleeperSource);
      var exe = p.join(
        dir.path,
        'sleeper_${++index}${Platform.isWindows ? '.exe' : ''}',
      );
      var result = await shell.runExecutableArguments(dartExecutable!, [
        'compile',
        'exe',
        source.path,
        '-o',
        exe,
      ]);
      expect(result.exitCode, 0, reason: result.errText);
      return exe;
    }

    /// Starts [exe] with [arguments], returns its process and its exit.
    Future<(Process, Future<ProcessResult>)> start(
      String exe,
      List<String> arguments,
    ) async {
      var started = Completer<Process>();
      var run = shell.runExecutableArguments(
        exe,
        arguments,
        onProcess: started.complete,
      );
      return (await started.future, run);
    }

    /// Waits for [count] processes of [exe].
    Future<List<int>> waitProcesses(String exe, int count) async {
      var pids = <int>[];
      for (var i = 0; i < 300; i++) {
        pids = await ShellProcesses.findByExecutable(exe);
        if (pids.length >= count) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(pids, hasLength(count));
      return pids;
    }

    test('isRunning', () async {
      expect(await ShellProcesses.isRunning(pid), isTrue);
      var exe = await compileSleeper();
      var (process, run) = await start(exe, ['0']);
      expect(await ShellProcesses.isRunning(process.pid), isTrue);
      process.kill(ProcessSignal.sigkill);
      await run;
      expect(await ShellProcesses.isRunning(process.pid), isFalse);
    });

    test('find and kill a tree', () async {
      var exe = await compileSleeper();
      expect(await ShellProcesses.findByExecutable(exe), isEmpty);
      // The sleeper, its child and its grandchild.
      var (process, run) = await start(exe, ['2']);
      var pids = await waitProcesses(exe, 3);
      expect(pids, contains(process.pid));
      var descendants = await ShellProcesses.descendantsOf(process.pid);
      expect(descendants, unorderedEquals(pids.toSet()..remove(process.pid)));
      // The relative path too.
      expect(
        await ShellProcesses.findByExecutable(p.relative(exe)),
        unorderedEquals(pids),
      );

      expect(await ShellProcesses.kill([process.pid], tree: true), isEmpty);
      expect((await run).exitCode, isNot(0));
      expect(await ShellProcesses.findByExecutable(exe), isEmpty);
      for (var pid in pids) {
        expect(await ShellProcesses.isRunning(pid), isFalse);
      }
      // Nothing to kill.
      expect(await ShellProcesses.kill([]), isEmpty);
      expect(await ShellProcesses.kill([pid]), isEmpty);
      expect(await ShellProcesses.isRunning(pid), isTrue);
    });

    test('kill without the tree', () async {
      var exe = await compileSleeper();
      var (process, run) = await start(exe, ['1']);
      var pids = await waitProcesses(exe, 2);
      var child = pids.singleWhere((pid) => pid != process.pid);
      expect(await ShellProcesses.kill([process.pid]), isEmpty);
      await run;
      // The orphan child still runs.
      expect(await ShellProcesses.isRunning(child), isTrue);
      expect(await ShellProcesses.kill([child]), isEmpty);
      expect(await ShellProcesses.findByExecutable(exe), isEmpty);
    });

    test('sigkill after the timeout', () async {
      var exe = await compileSleeper();
      var (process, run) = await start(exe, ['1', '--ignore-sigterm']);
      var pids = await waitProcesses(exe, 2);
      var stopwatch = Stopwatch()..start();
      expect(
        await ShellProcesses.kill(
          [process.pid],
          tree: true,
          timeout: const Duration(milliseconds: 500),
        ),
        isEmpty,
      );
      expect(
        stopwatch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 500)),
      );
      await run;
      for (var pid in pids) {
        expect(await ShellProcesses.isRunning(pid), isFalse);
      }
    }, testOn: '!windows');

    test('Shell.kill sigkill kills the descendants', () async {
      var exe = await compileSleeper();
      var (process, run) = await start(exe, ['2']);
      var pids = await waitProcesses(exe, 3);
      shell.kill(ProcessSignal.sigkill);
      // A killed run throws.
      await expectLater(run, throwsA(isA<ShellException>()));
      for (var i = 0; i < 50; i++) {
        if ((await ShellProcesses.findByExecutable(exe)).isEmpty) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(await ShellProcesses.findByExecutable(exe), isEmpty);
      expect(pids, contains(process.pid));
    });

    /// Waits for the processes of [exe] to be gone, at most [timeout].
    Future<void> waitGone(String exe, {required Duration timeout}) async {
      var stopwatch = Stopwatch()..start();
      while (stopwatch.elapsed < timeout &&
          (await ShellProcesses.findByExecutable(exe)).isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(await ShellProcesses.findByExecutable(exe), isEmpty);
    }

    test('Shell.kill() kills the descendants', () async {
      var exe = await compileSleeper();
      var (process, run) = await start(exe, ['2']);
      var pids = await waitProcesses(exe, 3);
      expect(pids, contains(process.pid));
      expect(shell.kill(), isTrue);
      await expectLater(run, throwsA(isA<ShellException>()));
      // sigterm is enough, well before the grace period.
      await waitGone(exe, timeout: const Duration(seconds: 3));
    });

    test('Shell.kill() sigkill after the grace period', () async {
      var exe = await compileSleeper();
      var (_, run) = await start(exe, ['1', '--ignore-sigterm']);
      await waitProcesses(exe, 2);
      var stopwatch = Stopwatch()..start();
      shell.kill();
      await expectLater(run, throwsA(isA<ShellException>()));
      await waitGone(exe, timeout: const Duration(seconds: 15));
      expect(stopwatch.elapsed, greaterThanOrEqualTo(shellKillGracePeriod));
    }, testOn: '!windows');

    test('Shell.kill(sigterm) signals the command only', () async {
      var exe = await compileSleeper();
      var (process, run) = await start(exe, ['1']);
      var pids = await waitProcesses(exe, 2);
      var child = pids.singleWhere((pid) => pid != process.pid);
      shell.kill(ProcessSignal.sigterm);
      await expectLater(run, throwsA(isA<ShellException>()));
      // The orphan child still runs.
      expect(await ShellProcesses.isRunning(child), isTrue);
      expect(await ShellProcesses.kill([child]), isEmpty);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
