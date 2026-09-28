import 'package:path/path.dart' as p;

/// Operating system kind for [DartToolPaths].
enum DartToolOs {
  /// Linux.
  linux,

  /// macOS.
  macos,

  /// Windows.
  windows,
}

/// Where `dart pub global activate` and `dart install` put their files,
/// computed from an environment map so that every platform can be tested.
///
/// Rules (verified against the sources on 2026-09-28):
/// - pub cache (pub `system_cache.dart`): `PUB_CACHE`, else
///   `%LOCALAPPDATA%\Pub\Cache` on Windows, else `~/.pub-cache`; binstubs in
///   its `bin` directory.
/// - Dart data home (package `dart_data_home`): `DART_DATA_HOME`, else the OS
///   state directory for `Dart`: `%LOCALAPPDATA%\Dart`,
///   `~/Library/Application Support/Dart`, `$XDG_STATE_HOME/Dart` or
///   `~/.local/state/Dart`. `dart install` uses its `install` directory, with
///   links (or `.bat` wrappers) in `install/bin` and app bundles in
///   `install/app-bundles`.
///
/// Neither tool has a destination option: set `PUB_CACHE` or `DART_DATA_HOME`
/// before installing to change the location.
class DartToolPaths {
  /// Rules for [os] with [environment].
  DartToolPaths({required this.os, required this.environment});

  /// The operating system.
  final DartToolOs os;

  /// The environment variables used.
  final Map<String, String> environment;

  late final p.Context _context = p.Context(
    style: isWindows ? p.Style.windows : p.Style.posix,
  );

  /// True on Windows.
  bool get isWindows => os == DartToolOs.windows;

  /// Environment value, case insensitive on Windows.
  String? environmentValue(String key) {
    if (isWindows) {
      final upper = key.toUpperCase();
      for (final entry in environment.entries) {
        if (entry.key.toUpperCase() == upper) {
          return entry.value;
        }
      }
      return null;
    }
    return environment[key];
  }

  String _requireEnvironmentValue(String key) =>
      environmentValue(key) ??
      (throw StateError('Missing environment variable $key'));

  /// The user home (`HOME`, or `USERPROFILE` on Windows).
  String get homePath =>
      environmentValue('HOME') ??
      environmentValue('USERPROFILE') ??
      (throw StateError('Missing environment variable HOME or USERPROFILE'));

  /// The pub cache.
  String get pubCachePath {
    final override = environmentValue('PUB_CACHE');
    if (override != null) {
      return override;
    }
    if (isWindows) {
      return _context.join(
        _requireEnvironmentValue('LOCALAPPDATA'),
        'Pub',
        'Cache',
      );
    }
    return _context.join(homePath, '.pub-cache');
  }

  /// Where `dart pub global activate` puts its binstubs.
  String get pubCacheBinPath => _context.join(pubCachePath, 'bin');

  /// The Dart data home.
  String get dartDataHomePath {
    final override = environmentValue('DART_DATA_HOME');
    if (override != null) {
      return override;
    }
    switch (os) {
      case DartToolOs.windows:
        return _context.join(_requireEnvironmentValue('LOCALAPPDATA'), 'Dart');
      case DartToolOs.macos:
        return _context.join(
          homePath,
          'Library',
          'Application Support',
          'Dart',
        );
      case DartToolOs.linux:
        final stateHome =
            environmentValue('XDG_STATE_HOME') ??
            _context.join(homePath, '.local', 'state');
        return _context.join(stateHome, 'Dart');
    }
  }

  /// The `dart install` directory.
  String get dartInstallPath => _context.join(dartDataHomePath, 'install');

  /// Where `dart install` puts its links (or `.bat` wrappers on Windows).
  String get dartInstallBinPath => _context.join(dartInstallPath, 'bin');

  /// Where `dart install` puts its app bundles
  /// (`<package>/{hosted/<version>,git/<hash>,local}/bundle`).
  String get dartInstallAppBundlesPath =>
      _context.join(dartInstallPath, 'app-bundles');

  /// The `PATH` separator.
  String get pathSeparator => isWindows ? ';' : ':';

  /// The `PATH` entries, in order.
  List<String> get pathEntries => (environmentValue('PATH') ?? '')
      .split(pathSeparator)
      .where((entry) => entry.isNotEmpty)
      .toList();

  String _normalize(String dir) {
    var normalized = _context.normalize(dir);
    if (isWindows) {
      normalized = normalized.toLowerCase();
    }
    return normalized;
  }

  /// Index of [dir] in `PATH` (trailing separators and case on Windows
  /// ignored), -1 if absent.
  int pathIndexOf(String dir) {
    final normalized = _normalize(dir);
    final entries = pathEntries;
    for (var i = 0; i < entries.length; i++) {
      if (_normalize(entries[i]) == normalized) {
        return i;
      }
    }
    return -1;
  }

  /// True if [dir] is on `PATH`.
  bool isDirOnPath(String dir) => pathIndexOf(dir) >= 0;
}
