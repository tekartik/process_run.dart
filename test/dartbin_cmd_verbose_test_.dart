@TestOn("vm")
library process_run.dartbin_cmd_verbose_test;

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart' show runCmd;
import 'package:process_run/src/dartbin_cmd.dart';

void main() {
  group('dartbin_cmd_verbose', () {
    test('all', () async {
      expect((await runCmd(dartfmtCmd(['--help']), verbose: true)).exitCode, 0);
      expect(
          (await runCmd(dartanalyzerCmd(['--help']), verbose: true)).exitCode,
          0);
      expect((await runCmd(dart2jsCmd(['--help']), verbose: true)).exitCode, 0);
      expect((await runCmd(dartdocCmd(['--help']), verbose: true)).exitCode, 0);
      expect((await runCmd(pubCmd(['--help']), verbose: true)).exitCode, 0);
    });
  });
}
