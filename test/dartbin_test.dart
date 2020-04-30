@TestOn('vm')
library process_run.dartbin_test;

import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/src/script_filename.dart';
import 'package:process_run/which.dart';

void main() => defineTests();

void defineTests() {
  group('dartbin', () {
    group('dart', () {
      test('run_dart', () async {
        final result = await Process.run('dart', ['--version']);
        expect(result.stderr.toLowerCase(), contains('dart'));
        expect(result.stderr.toLowerCase(), contains('version'));
        // 'Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on 'linux_x64'\n'
      });

      test('run', () async {
        final result = await Process.run(dartExecutable, ['--version']);
        expect(result.stderr.toLowerCase(), contains('dart'));
        expect(result.stderr.toLowerCase(), contains('version'));
        // 'Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on 'linux_x64'\n'
      });

      test('dartExecutable_path', () {
        expect(isAbsolute(dartExecutable), isTrue);
        expect(
            Directory(join(dirname(dartExecutable), 'snapshots')).existsSync(),
            isTrue);
      });

      test('dart_empty_param', () async {
        final result = await Process.run(dartExecutable, []);
        expect(result.exitCode, 255);
      });

      test('dart_null_param', () async {
        try {
          await Process.run(dartExecutable, null);
          fail('should fail');
        } on ArgumentError catch (_) {}
      });
    });

    test('which', () {
      var whichDart = whichSync('dart');
      // might not be in path during the test
      if (whichDart != null) {
        expect(basename(whichDart), getBashOrExeExecutableFilename('dart'));
      }
    });

    group('help', () {
      test('dart', () async {
        var result = await Process.run(dartExecutable, ['--help']);
        expect(result.exitCode, 0);
        // help is on stderr
        expect(result.stdout, '');
        expect(result.stderr, contains('Usage: dart '));

        // Version is on stderr
        result = await Process.run(dartExecutable, ['--version']);
        expect(result.stdout, '');
        expect(result.stderr, contains('Dart VM'));
      });
    });

    test('dartVersion', () {
      expect(dartVersion, greaterThan(Version(2, 5, 0)));
    });

    test('dartChannel', () {
      // "TRAVIS_DART_VERSION": "stable"
      // print(Platform.version);
      expect(dartChannel, isNotNull);
      if (Platform.environment['TRAVIS_DART_VERSION'] == 'stable') {
        expect(dartChannel, dartChannelStable);
      }
      if (Platform.environment['TRAVIS_DART_VERSION'] == 'beta') {
        expect(dartChannel, dartChannelBeta);
      }
      if (Platform.environment['TRAVIS_DART_VERSION'] == 'dev') {
        expect(dartChannel, dartChannelDev);
      }
    });
  });
}
