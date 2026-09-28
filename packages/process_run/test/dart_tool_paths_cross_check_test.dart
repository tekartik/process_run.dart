@TestOn('vm')
library;

import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:dart_data_home/dart_data_home.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

/// The hand-written rules of [DartToolPaths] must match the official ones:
/// `BaseDirectories('Dart').stateHome` (cli_util, used by the SDK) and
/// `getDartDataHome('install')` (dart_data_home, used by `dart install`).
/// Both read the OS from `Platform`, so this only checks the current one;
/// CI runs it on Linux, macOS and Windows.
void main() {
  final os = Platform.isWindows
      ? DartToolOs.windows
      : Platform.isMacOS
      ? DartToolOs.macos
      : DartToolOs.linux;

  void check(Map<String, String> environment) {
    final paths = DartToolPaths(os: os, environment: environment);
    // cli_util alone does not know DART_DATA_HOME (verified: with the
    // override set, stateHome still answers the OS state directory).
    if (!environment.containsKey('DART_DATA_HOME')) {
      expect(
        paths.dartDataHomePath,
        p.normalize(
          BaseDirectories('Dart', environment: environment).stateHome,
        ),
      );
    }
    expect(
      paths.dartInstallPath,
      p.normalize(getDartDataHome('install', environment: environment)),
    );
  }

  test('current environment', () {
    check(Platform.environment);
  });

  test('fake environment', () {
    final home = Platform.isWindows ? r'C:\Users\u' : '/home/u';
    check({
      if (Platform.isWindows) 'USERPROFILE': home else 'HOME': home,
      if (Platform.isWindows) 'LOCALAPPDATA': p.join(home, 'AppData', 'Local'),
    });
    check({
      if (Platform.isWindows) 'USERPROFILE': home else 'HOME': home,
      if (Platform.isWindows) 'LOCALAPPDATA': p.join(home, 'AppData', 'Local'),
      'DART_DATA_HOME': p.join(home, 'data'),
    });
    if (Platform.isLinux) {
      check({'HOME': home, 'XDG_STATE_HOME': '/state'});
    }
  });
}
