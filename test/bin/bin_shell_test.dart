@TestOn('vm')
library process_run.test.bin.shell_bin_test;

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

var shell = Shell(
    environment: ShellEnvironment()..aliases['ds'] = 'dart bin/shell.dart',
    verbose: false);

void main() {
  group('bin_shell', () {
    test('version', () async {
      var output = (await shell.run('ds --version')).outText.trim();
      await shell.run('ds env edit -h');
      expect(Version.parse(output), shellBinVersion);
    });

    test('help', () async {
      var outLines = (await shell.run('ds --help')).outLines;
      expect(outLines.length, greaterThan(17));
    });
    test('run', () async {
      await shell.run('ds run --help');
      await shell.run('ds run echo Hello World');
    });

    test('env', () async {
      await shell.run('ds env -u -i');
      await shell.run('ds env -l -i');
    });

    test('path', () async {
      await shell.run('ds env path prepend dummy1');
      await shell.run('ds env path dump');
    });

    test('var', () async {
      await shell.run('ds env var set TEST_VALUE dummy1');
      await shell.run('ds env var dump');
    });

    test('alias', () async {
      await shell.run('ds env alias set TEST_ALIAS test command');
      await shell.run('ds env alias dump');
    });
  });
}
