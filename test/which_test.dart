@TestOn("vm")
library process_run.which_test;

import 'dart:io';
import 'package:dev_test/test.dart';
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
      ProcessResult result = await runCmd(cmd);
      expect(result.stderr.toLowerCase(), contains("dart"));
      expect(result.stderr.toLowerCase(), contains("version"));
    });

    test('no_env', () {
      var dartExecutableFilename =
          whichSync('dart', environment: <String, String>{});
      expect(dartExecutableFilename, isNull);
      expect(whichSync('pub', environment: <String, String>{}), isNull);

      dartExecutableFilename = whichSync('dart',
          environment: <String, String>{'PATH': dirname(dartExecutable)});
      expect(dartExecutableFilename, isNotNull);
      expect(
          whichSync('pub',
              environment: <String, String>{'PATH': dirname(dartExecutable)}),
          isNotNull);
    });

    test('echo', () async {
      if (Platform.isWindows) {
        expect(whichSync('echo'), isNull);
      }
    });
  });
}
