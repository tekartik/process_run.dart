@TestOn('vm')
library process_run.dartdoc_test;

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

String testOut = join('.dart_tool', 'process_run', 'test');

void main() => defineTests();

void defineTests() {
  group('dartdoc', () {
    test('build', () async {
      // from dartdoc: exec '$DART' --packages='$BIN_DIR/snapshots/resources/dartdoc/.packages' '$SNAPSHOT' '$@'

      final result = await runExecutableArguments(
          'dart', ['doc', '--output', join(testOut, 'dartdoc_build'), '.'],
          verbose: true);
      //expect(result.stdout, contains('dartdoc'));
      expect(result.exitCode, 0);
      //}, skip: 'failed on SDK 1.19.0'); - fixed in 1.19.1
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
