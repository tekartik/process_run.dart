import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:synchronized/synchronized.dart';

/// Serializes [compileTestExecutable]: one compile at a time in this process.
final _lock = Lock();

/// The executables already checked (up to date) by this process.
final _checkedPaths = <String>{};

/// Compiles the test program [source] (relative to [path], the root of the
/// `process_run_test` package, the current directory by default) for the
/// current host into `<path>/build/<linux|macos|windows>/<name>[.exe]` when
/// needed, returns its absolute path.
///
/// An existing executable is reused when its `--version` is [version]:
/// checked once per process, the calls are serialized (concurrent calls
/// compile once). [force] compiles anyway, [verbose] shows the commands.
/// Throws a [ShellException] when the compile fails.
Future<String> compileTestExecutable({
  required String name,
  required String source,
  required Version version,
  String? path,
  bool force = false,
  bool? verbose,
}) => _lock.synchronized(() async {
  var folder = Platform.isWindows
      ? 'windows'
      : (Platform.isMacOS ? 'macos' : 'linux');
  var exeExtension = Platform.isWindows ? '.exe' : '';
  var exePath = normalize(
    absolute(joinAll([?path, 'build', folder, '$name$exeExtension'])),
  );
  if (!force && _checkedPaths.contains(exePath)) {
    return exePath;
  }
  var shell = Shell(verbose: verbose ?? false, workingDirectory: path);
  var needCompile = force || !File(exePath).existsSync();
  if (!needCompile) {
    try {
      var result = await shell
          .cloneWithOptions(shell.options.clone(throwOnError: false))
          .runExecutableArguments(exePath, ['--version']);
      needCompile =
          result.exitCode != 0 ||
          Version.parse(result.outText.trim()) != version;
    } catch (_) {
      needCompile = true;
    }
  }
  if (needCompile) {
    await Directory(dirname(exePath)).create(recursive: true);
    await shell.runExecutableArguments(dartExecutable!, [
      'compile',
      'exe',
      source,
      '-o',
      exePath,
    ]);
  }
  _checkedPaths.add(exePath);
  return exePath;
});
