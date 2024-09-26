@TestOn('vm')
library;

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/import.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../src/compile_shell.dart';

void main() {
  late Shell shell;
  group('compiled_bin_shell', () {
    setUpAll(() async {
      var dsExePath = await compileShellBin(force: false);
      shell = Shell(
          environment: ShellEnvironment()..aliases['ds'] = dsExePath,
          verbose: false);
    });
    test('version', () async {
      var output = (await shell.run('ds --version')).outText.trim();
      await shell.run('ds env edit -h');
      expect(Version.parse(output), shellBinVersion);
    });
    group('env', () {
      group('path', () {
        test('user prepend', () async {
          var dummyPath = 'dummyUserPathPrepend';
          await shell.run('ds env --user path delete $dummyPath');
          var lines = (await shell.run('ds env --user path dump')).outLines;
          expect(lines, isNot(contains(dummyPath)));
          await shell.run('ds env --user path prepend $dummyPath');
          lines = (await shell.run('ds env --user path dump')).outLines;
          expect(lines, contains(dummyPath));
          await shell.run('ds env --user path delete $dummyPath');
          lines = (await shell.run('ds env --user path dump')).outLines;
          expect(lines, isNot(contains(dummyPath)));
        });
        test('local prepend', () async {
          var dummyPath = 'dummyLocalPathPrepend';
          await shell.run('ds env --user path delete $dummyPath');
          var lines = (await shell.run('ds env --user path dump')).outLines;
          expect(lines, isNot(contains(dummyPath)));
          await shell.run('ds env --user path prepend $dummyPath');
          lines = (await shell.run('ds env --user path dump')).outLines;
          expect(lines, contains(dummyPath));
          await shell.run('ds env --user path delete $dummyPath');
          lines = (await shell.run('ds env --user path dump')).outLines;
          expect(lines, isNot(contains(dummyPath)));
        });
      });
    });
  });
}
