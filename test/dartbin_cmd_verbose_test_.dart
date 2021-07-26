@TestOn('vm')
library process_run.dartbin_cmd_verbose_test;

import 'package:process_run/cmd_run.dart' show runCmd;
import 'package:process_run/src/dartbin_cmd.dart';
import 'package:test/test.dart';

void main() {
  group('dartbin_cmd_verbose', () {
    test('all', () async {
      expect(
          (await runCmd(
                  DartFmtCmd(// ignore: deprecated_member_use_from_same_package
                      ['--help']),
                  verbose: true))
              .exitCode,
          0);
      expect(
          (await runCmd(DartAnalyzerCmd(['--help']), verbose: true)).exitCode,
          0);
      expect((await runCmd(Dart2JsCmd(['--help']), verbose: true)).exitCode, 0);
      expect((await runCmd(DartDocCmd(['--help']), verbose: true)).exitCode, 0);
      expect((await runCmd(PubCmd(['--help']), verbose: true)).exitCode, 0);
    });
  });
}
