@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void main() {
  group('dart_tool_paths', () {
    group('linux', () {
      final paths = DartToolPaths(
        os: DartToolOs.linux,
        environment: {
          'HOME': '/home/u',
          'PATH':
              '/home/u/.pub-cache/bin:/usr/bin:/home/u/.local/state/Dart/install/bin/',
        },
      );
      test('defaults', () {
        expect(paths.pubCachePath, '/home/u/.pub-cache');
        expect(paths.pubCacheBinPath, '/home/u/.pub-cache/bin');
        expect(paths.dartDataHomePath, '/home/u/.local/state/Dart');
        expect(paths.dartInstallPath, '/home/u/.local/state/Dart/install');
        expect(
          paths.dartInstallBinPath,
          '/home/u/.local/state/Dart/install/bin',
        );
        expect(
          paths.dartInstallAppBundlesPath,
          '/home/u/.local/state/Dart/install/app-bundles',
        );
      });
      test('path', () {
        expect(paths.pathEntries.length, 3);
        expect(paths.pathIndexOf('/home/u/.pub-cache/bin'), 0);
        // Trailing separator ignored
        expect(paths.pathIndexOf('/home/u/.local/state/Dart/install/bin'), 2);
        expect(paths.isDirOnPath('/usr/bin'), isTrue);
        expect(paths.isDirOnPath('/opt/bin'), isFalse);
      });
      test('overrides', () {
        final overridden = DartToolPaths(
          os: DartToolOs.linux,
          environment: {
            'HOME': '/home/u',
            'PUB_CACHE': '/tmp/cache',
            'DART_DATA_HOME': '/tmp/data',
          },
        );
        expect(overridden.pubCacheBinPath, '/tmp/cache/bin');
        expect(overridden.dartInstallBinPath, '/tmp/data/install/bin');
        final xdg = DartToolPaths(
          os: DartToolOs.linux,
          environment: {'HOME': '/home/u', 'XDG_STATE_HOME': '/state'},
        );
        expect(xdg.dartInstallBinPath, '/state/Dart/install/bin');
      });
      test('missing home', () {
        final none = DartToolPaths(os: DartToolOs.linux, environment: {});
        expect(() => none.pubCachePath, throwsStateError);
        expect(none.pathEntries, isEmpty);
      });
    });

    test('macos', () {
      final paths = DartToolPaths(
        os: DartToolOs.macos,
        environment: {'HOME': '/Users/u'},
      );
      expect(paths.pubCacheBinPath, '/Users/u/.pub-cache/bin');
      expect(
        paths.dartInstallBinPath,
        '/Users/u/Library/Application Support/Dart/install/bin',
      );
    });

    test('windows', () {
      final paths = DartToolPaths(
        os: DartToolOs.windows,
        environment: {
          'USERPROFILE': r'C:\Users\u',
          'LocalAppData': r'C:\Users\u\AppData\Local',
          'Path': r'C:\Users\u\AppData\Local\Pub\Cache\bin;C:\Windows',
        },
      );
      expect(paths.homePath, r'C:\Users\u');
      expect(paths.pubCachePath, r'C:\Users\u\AppData\Local\Pub\Cache');
      expect(paths.pubCacheBinPath, r'C:\Users\u\AppData\Local\Pub\Cache\bin');
      expect(paths.dartDataHomePath, r'C:\Users\u\AppData\Local\Dart');
      expect(
        paths.dartInstallBinPath,
        r'C:\Users\u\AppData\Local\Dart\install\bin',
      );
      // Case insensitive keys and entries
      expect(paths.environmentValue('PATH'), isNotNull);
      expect(paths.pathIndexOf(r'c:\users\u\appdata\local\pub\cache\bin'), 0);
      expect(paths.pathIndexOf(r'C:\Windows\'), 1);
      expect(paths.isDirOnPath(r'C:\Other'), isFalse);
    });

    test('current platform', () {
      expect(p.basename(pubCacheBinPath), 'bin');
      expect(p.basename(p.dirname(dartInstallBinPath)), 'install');
      expect(dartInstallPath, p.dirname(dartInstallBinPath));
      expect(dartDataHomePath, p.dirname(dartInstallPath));
      expect(dartToolPaths.isWindows, Platform.isWindows);
      final environment = Platform.environment;
      if (environment['PUB_CACHE'] == null && !Platform.isWindows) {
        expect(pubCachePath, p.join(environment['HOME']!, '.pub-cache'));
      }
      if (environment['DART_DATA_HOME'] != null) {
        expect(dartDataHomePath, environment['DART_DATA_HOME']);
      }
    });
  });
}
