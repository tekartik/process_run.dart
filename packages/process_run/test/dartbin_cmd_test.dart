@TestOn('vm')
library process_run.dartbin_cmd_test;

import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'dartbin_test.dart';

void main() {
  group('dartbin_cmd', () {
    test('api', () {
      // ignore: unnecessary_statements
      getDartBinVersion;
    });
    test('dartcmd_arguments', () async {
      ProcessCmd cmd = DartCmd(['--version']);
      expect(cmd.executable, dartExecutable);
      expect(cmd.arguments, ['--version']);
      final result = await runCmd(cmd);
      testDartVersionOutput(result);
      // 'Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on 'linux_x64'\n'
    });
    test('others', () async {
      expect((await runCmd(DartCmd(['--help']))).exitCode, 0);
      expect((await runCmd(PubCmd(['--help']))).exitCode, 0);
      //expect((await runCmd(DartDevkCmd(['--help']))).exitCode, 0);
    });

    test('toString', () {
      expect(PubCmd(['--help']).toString(), 'dart pub --help');
      expect(DartCmd(['--help']).toString(), 'dart --help');
    });

    test('get version', () async {
      var version = await getDartBinVersion();
      // Always present
      expect(version, greaterThan(Version(2, 0, 0)));
    });

    test('missing dart', () async {
      // ignore: deprecated_member_use_from_same_package
      flutterExecutablePath = null;
      platformEnvironment = <String, String>{};
      try {
        var version = await getDartBinVersion();
        // Always present
        expect(version, greaterThan(Version(2, 0, 0)));
      } finally {
        // ignore: deprecated_member_use_from_same_package
        flutterExecutablePath = null;
        platformEnvironment = null;
      }
      // Always present
      var version = await getDartBinVersion();
      if (version != null) {
        expect(version, greaterThan(Version(2, 0, 0)));
      }
    });
  });
}
