import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart' as p;
import 'package:process_run/src/shell.dart' show Shell;

/// A process of the process table, see [readProcessTable].
class ProcessTableEntry {
  /// A process of the table: [pid], its parent [ppid], its [created] time,
  /// its [executable] path and its [command] line when known.
  ProcessTableEntry({
    required this.pid,
    required this.ppid,
    this.created = 0,
    this.executable,
    this.command,
  });

  /// The process id.
  final int pid;

  /// The parent process id, 0 when unknown.
  final int ppid;

  /// The creation time (Windows: a file time, UTC), 0 when unknown. Guards
  /// against a reused parent pid on Windows, where an orphan keeps the pid
  /// of its dead parent.
  final int created;

  /// The executable path: the target of `/proc/<pid>/exe` on Linux (without
  /// the ` (deleted)` suffix of a replaced file), the executable path on
  /// Windows; null when unknown (another user's process, macOS).
  final String? executable;

  /// The command line (`ps` command on macOS, the process started with its
  /// arguments), null when unknown.
  final String? command;

  @override
  String toString() => '$pid (ppid $ppid) ${executable ?? command ?? ''}';
}

/// The state and the parent pid of a `/proc/<pid>/stat` [content] (`1234
/// (name) S 1 ...`, the name may hold spaces and parentheses), null when it
/// cannot be parsed.
({String state, int ppid})? parseLinuxProcStat(String content) {
  var end = content.lastIndexOf(')');
  if (end < 0) {
    return null;
  }
  var fields = content.substring(end + 1).trim().split(' ');
  if (fields.length < 2) {
    return null;
  }
  var ppid = int.tryParse(fields[1]);
  if (ppid == null) {
    return null;
  }
  return (state: fields[0], ppid: ppid);
}

/// True for a zombie (`Z`) or dead (`X`) process state (Linux `stat`, `ps`
/// stat): exited, not running anymore.
bool _isExitedState(String state) =>
    state.startsWith('Z') || state.startsWith('X');

/// The processes of a `ps -axo pid=,ppid=,stat=,command=` [output], the
/// exited ones (zombies) excluded.
List<ProcessTableEntry> parsePsProcessTable(String output) {
  var entries = <ProcessTableEntry>[];
  var regExp = RegExp(r'^\s*(\d+)\s+(\d+)\s+(\S+)\s*(.*)$');
  for (var line in output.split('\n')) {
    var match = regExp.firstMatch(line.trimRight());
    if (match == null || _isExitedState(match.group(3)!)) {
      continue;
    }
    entries.add(
      ProcessTableEntry(
        pid: int.parse(match.group(1)!),
        ppid: int.parse(match.group(2)!),
        command: match.group(4),
      ),
    );
  }
  return entries;
}

/// The PowerShell command listing the processes on Windows, one
/// `pid|ppid|created|path` line each, see [parseWindowsProcessTable].
const _windowsProcessTableCommand =
    r'Get-CimInstance Win32_Process | ForEach-Object { '
    r"'{0}|{1}|{2}|{3}' -f $_.ProcessId, $_.ParentProcessId, "
    r'$(if ($_.CreationDate) { $_.CreationDate.ToFileTimeUtc() } else { 0 }), '
    r'$_.ExecutablePath }';

/// The processes of the `pid|ppid|created|path` lines of [output] (the
/// PowerShell process list on Windows).
List<ProcessTableEntry> parseWindowsProcessTable(String output) {
  var entries = <ProcessTableEntry>[];
  for (var line in output.split('\n')) {
    var parts = line.trim().split('|');
    if (parts.length < 4) {
      continue;
    }
    var pid = int.tryParse(parts[0]);
    if (pid == null) {
      continue;
    }
    var executable = parts.sublist(3).join('|');
    entries.add(
      ProcessTableEntry(
        pid: pid,
        ppid: int.tryParse(parts[1]) ?? 0,
        created: int.tryParse(parts[2]) ?? 0,
        executable: executable.isEmpty ? null : executable,
      ),
    );
  }
  return entries;
}

/// The processes of `/proc` (Linux), the exited ones (zombies) excluded.
List<ProcessTableEntry> _readLinuxProcessTable() {
  var entries = <ProcessTableEntry>[];
  List<io.FileSystemEntity> dirs;
  try {
    dirs = io.Directory('/proc').listSync(followLinks: false);
  } catch (_) {
    return entries;
  }
  for (var dir in dirs) {
    var pid = int.tryParse(p.basename(dir.path));
    if (pid == null) {
      continue;
    }
    var stat = _readLinuxProcStat(pid);
    if (stat == null || _isExitedState(stat.state)) {
      continue;
    }
    String? executable;
    try {
      executable = linuxProcExePath(
        io.Link(p.join(dir.path, 'exe')).targetSync(),
      );
    } catch (_) {
      // A kernel thread or the process of another user.
    }
    entries.add(
      ProcessTableEntry(pid: pid, ppid: stat.ppid, executable: executable),
    );
  }
  return entries;
}

/// The state and parent of the Linux process [pid], null when gone.
({String state, int ppid})? _readLinuxProcStat(int pid) {
  try {
    return parseLinuxProcStat(io.File('/proc/$pid/stat').readAsStringSync());
  } catch (_) {
    return null;
  }
}

/// The executable path of a `/proc/<pid>/exe` link [target], without the
/// ` (deleted)` suffix of an executable replaced or removed since.
String linuxProcExePath(String target) {
  const deleted = ' (deleted)';
  return target.endsWith(deleted)
      ? target.substring(0, target.length - deleted.length)
      : target;
}

/// The running processes of this machine: their pid, parent pid and, when
/// known, executable path (Linux, Windows) or command line (macOS).
///
/// Linux reads `/proc`, macOS runs `ps`, Windows runs PowerShell
/// (`Get-CimInstance Win32_Process`, about a second). Empty when the table
/// cannot be read.
Future<List<ProcessTableEntry>> readProcessTable() async {
  if (io.Platform.isLinux) {
    return _readLinuxProcessTable();
  }
  try {
    if (io.Platform.isWindows) {
      var result = await io.Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        _windowsProcessTableCommand,
      ]);
      return parseWindowsProcessTable(result.stdout.toString());
    }
    var result = await io.Process.run('ps', [
      '-axo',
      'pid=,ppid=,stat=,command=',
    ]);
    return parsePsProcessTable(result.stdout.toString());
  } catch (_) {
    return [];
  }
}

/// [readProcessTable] synchronously (`Shell.kill`), Linux and macOS only
/// (empty on Windows).
List<ProcessTableEntry> readProcessTableSync() {
  if (io.Platform.isLinux) {
    return _readLinuxProcessTable();
  }
  if (io.Platform.isWindows) {
    return [];
  }
  try {
    var result = io.Process.runSync('ps', [
      '-axo',
      'pid=,ppid=,stat=,command=',
    ]);
    return parsePsProcessTable(result.stdout.toString());
  } catch (_) {
    return [];
  }
}

/// The descendants of [pids] in [table] (their children, the children of
/// these...), the closest first, [pids] excluded.
///
/// A child created before its parent (a reused parent pid on Windows) is
/// not a descendant.
List<int> processTableDescendantIds(
  List<ProcessTableEntry> table,
  Iterable<int> pids,
) {
  var byPid = {for (var entry in table) entry.pid: entry};
  var children = <int, List<ProcessTableEntry>>{};
  for (var entry in table) {
    if (entry.ppid != entry.pid) {
      children.putIfAbsent(entry.ppid, () => []).add(entry);
    }
  }
  var roots = pids.toSet();
  var seen = <int>{...roots};
  var descendants = <int>[];
  var queue = [...roots];
  while (queue.isNotEmpty) {
    var parentPid = queue.removeAt(0);
    var parentCreated = byPid[parentPid]?.created ?? 0;
    for (var child in children[parentPid] ?? const <ProcessTableEntry>[]) {
      if (parentCreated != 0 &&
          child.created != 0 &&
          child.created < parentCreated) {
        continue;
      }
      if (seen.add(child.pid)) {
        descendants.add(child.pid);
        queue.add(child.pid);
      }
    }
  }
  return descendants;
}

/// The paths a process of [executable] may show: the absolute path and its
/// real path (symbolic links resolved).
Set<String> _executablePaths(String executable) {
  var path = p.normalize(p.absolute(executable));
  var paths = {path};
  try {
    paths.add(io.File(path).resolveSymbolicLinksSync());
  } catch (_) {
    try {
      // Removed since: its folder may still be reached through a link.
      paths.add(
        p.join(
          io.Directory(p.dirname(path)).resolveSymbolicLinksSync(),
          p.basename(path),
        ),
      );
    } catch (_) {}
  }
  return paths;
}

/// True when [entry] runs one of [paths]: its executable (case insensitive
/// on Windows), or its command line starting with it (macOS).
bool _entryRunsExecutable(ProcessTableEntry entry, Set<String> paths) {
  var executable = entry.executable;
  if (executable != null) {
    if (io.Platform.isWindows) {
      var lower = executable.toLowerCase();
      return paths.any((path) => path.toLowerCase() == lower);
    }
    return paths.contains(executable);
  }
  var command = entry.command;
  if (command != null) {
    return paths.any((path) => command == path || command.startsWith('$path '));
  }
  return false;
}

/// The pids of the running descendants of [pid], synchronously, Linux and
/// macOS only (empty on Windows), see [ShellProcesses.descendantsOf]. Used
/// by `Shell.kill`.
List<int> findProcessDescendantIdsSync(int pid) =>
    processTableDescendantIds(readProcessTableSync(), [pid]);

/// Sends [signal] to [pid], false when it could not be delivered (gone, or
/// not allowed).
bool _killPid(int pid, io.ProcessSignal signal) {
  try {
    return io.Process.killPid(pid, signal);
  } catch (_) {
    return false;
  }
}

/// Waits for [pids] to exit, at most [timeout]; returns the ones still
/// running.
Future<List<int>> _waitProcessesExit(List<int> pids, Duration timeout) async {
  var stopwatch = Stopwatch()..start();
  var remaining = pids;
  while (true) {
    var running = <int>[];
    for (var pid in remaining) {
      if (await ShellProcesses.isRunning(pid)) {
        running.add(pid);
      }
    }
    remaining = running;
    if (remaining.isEmpty || stopwatch.elapsed >= timeout) {
      return remaining;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

/// The grace period of `Shell.kill()` (no signal): the processes still
/// running after it are killed with `sigkill`.
const shellKillGracePeriod = Duration(seconds: 5);

/// `Shell.kill()` (no signal) once [process] and its [descendants] got
/// `sigterm`: waits for them to exit, at most [gracePeriod], then kills the
/// ones still running with `sigkill`.
///
/// [process] is followed by its exit code (no pid reuse), the descendants by
/// their pid.
Future<void> shellKillAfterGracePeriod(
  io.Process process,
  List<int> descendants, {
  Duration gracePeriod = shellKillGracePeriod,
}) async {
  var exited = false;
  unawaited(
    process.exitCode.then((_) {
      exited = true;
    }),
  );
  var stopwatch = Stopwatch()..start();
  var remaining = descendants;
  while (true) {
    remaining = [
      for (var pid in remaining)
        if (await ShellProcesses.isRunning(pid)) pid,
    ];
    if ((exited && remaining.isEmpty) || stopwatch.elapsed >= gracePeriod) {
      break;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  if (!exited) {
    try {
      process.kill(io.ProcessSignal.sigkill);
    } catch (_) {}
  }
  for (var pid in remaining) {
    _killPid(pid, io.ProcessSignal.sigkill);
  }
}

/// The processes of the machine by their pid, the way the `ps`, `pgrep` and
/// `kill` commands of a shell handle them: any process, not only the ones a
/// [Shell] started (an app started from another terminal), on Linux
/// (`/proc`), macOS (`ps`) and Windows (PowerShell, `tasklist`).
///
/// A process of another user is seen ([isRunning], [descendantsOf]) but
/// usually not found by its executable ([findByExecutable], except on macOS)
/// and cannot be killed ([kill], unless root or administrator).
///
/// Not to be confused with [Shell.kill], which kills the command a shell
/// runs.
abstract final class ShellProcesses {
  /// The pids of the running processes of [executable] (the path of an
  /// executable file, relative to the current directory or absolute), empty
  /// when none.
  ///
  /// Linux and Windows compare the executable of each process (a process of
  /// an executable replaced since is found too on Linux), only for the
  /// processes of the current user; macOS compares the command line of each
  /// process (the executable started by its path, the way `Process.start`
  /// does), the processes of every user. The current process may be one of
  /// them.
  static Future<List<int>> findByExecutable(String executable) async {
    var paths = _executablePaths(executable);
    return [
      for (var entry in await readProcessTable())
        if (_entryRunsExecutable(entry, paths)) entry.pid,
    ];
  }

  /// The pids of the running descendants of [pid] (its children, their
  /// children...), the closest first, empty when none.
  ///
  /// Read them before killing [pid]: an orphan gets another parent.
  static Future<List<int>> descendantsOf(int pid) async =>
      processTableDescendantIds(await readProcessTable(), [pid]);

  /// True when the process [pid] is running: false once exited (a zombie,
  /// not reaped yet by its parent, is not running).
  ///
  /// Linux reads `/proc/<pid>/stat`, macOS runs `ps`, Windows `tasklist`.
  static Future<bool> isRunning(int pid) async {
    if (io.Platform.isLinux) {
      var stat = _readLinuxProcStat(pid);
      return stat != null && !_isExitedState(stat.state);
    }
    try {
      if (io.Platform.isWindows) {
        var result = await io.Process.run('tasklist', [
          '/FI',
          'PID eq $pid',
          '/FO',
          'CSV',
          '/NH',
        ]);
        return result.stdout.toString().contains('"$pid"');
      }
      var result = await io.Process.run('ps', ['-o', 'stat=', '-p', '$pid']);
      var state = result.stdout.toString().trim();
      return result.exitCode == 0 && state.isNotEmpty && !_isExitedState(state);
    } catch (_) {
      return false;
    }
  }

  /// Kills the processes [pids] and waits for them to exit: [signal]
  /// (`sigterm` by default) first, then `sigkill` for the ones still running
  /// after [timeout] (2 more seconds for these).
  ///
  /// [tree] kills their descendants too ([descendantsOf], read before the
  /// first signal). The current process is never killed. On Windows every
  /// signal terminates the process at once.
  ///
  /// Returns the pids still running at the end (the descendants included,
  /// the ones not allowed to be killed too), empty when all exited.
  static Future<List<int>> kill(
    Iterable<int> pids, {
    io.ProcessSignal signal = io.ProcessSignal.sigterm,
    bool tree = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    var targets = <int>{...pids};
    if (tree && targets.isNotEmpty) {
      targets.addAll(processTableDescendantIds(await readProcessTable(), pids));
    }
    targets.remove(io.pid);
    if (targets.isEmpty) {
      return [];
    }
    for (var pid in targets) {
      _killPid(pid, signal);
    }
    var remaining = await _waitProcessesExit(targets.toList(), timeout);
    if (remaining.isNotEmpty && signal != io.ProcessSignal.sigkill) {
      for (var pid in remaining) {
        _killPid(pid, io.ProcessSignal.sigkill);
      }
      remaining = await _waitProcessesExit(
        remaining,
        const Duration(seconds: 2),
      );
    }
    return remaining;
  }
}
