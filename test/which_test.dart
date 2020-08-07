@TestOn('vm')
library process_run.which_test;

import 'dart:io';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/flutterbin_cmd.dart';
import 'package:process_run/src/script_filename.dart';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/which.dart';

void main() {
  group('which', () {
    test('dart', () async {
      var env = {'PATH': dartSdkBinDirPath};
      var dartExecutable = whichSync('dart', environment: env);
      expect(dartExecutable, isNotNull);
      print(dartExecutable);
      var cmd = ProcessCmd(dartExecutable, ['--version']);
      final result = await runCmd(cmd);
      expect(result.stderr.toLowerCase(), contains('dart'));
      expect(result.stderr.toLowerCase(), contains('version'));
    });

    test('no_env', () {
      var empty = <String, String>{};

      // We can always find dart and pub
      try {
        expect(whichSync('dart', environment: empty), dartExecutable);
      } on TestFailure catch (_) {
        if (!isFlutterSupportedSync) {
          rethrow;
        }
        // In case flutter in in the path first
        expect(
            whichSync('dart', environment: empty),
            join(dirname(whichSync('flutter')),
                getBashOrBatExecutableFilename('dart')));
      }
      expect(whichSync('pub', environment: empty), isNotNull);
      expect(whichSync('current_dir', environment: empty), isNull);

      expect(
          basename(whichSync('current_dir',
              environment: <String, String>{'PATH': join('test', 'src')})),
          Platform.isWindows ? 'current_dir.bat' : 'current_dir');
    });

    test('dart_env', () async {
      var empty = <String, String>{};

      // We can always find dart and pub
      try {
        // Normal
        expect(whichSync('dart', environment: empty), dartExecutable);
      } on TestFailure catch (_) {
        if (!isFlutterSupportedSync) {
          rethrow;
        }
        // In case flutter in in the path first
        expect(
            whichSync('dart', environment: empty),
            join(dirname(whichSync('flutter')),
                getBashOrBatExecutableFilename('dart')));
      }
    });

    test('echo', () async {
      if (Platform.isWindows) {
        expect(whichSync('echo'), isNull);
      }
    });
  });
}
