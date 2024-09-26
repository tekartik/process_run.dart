@TestOn('vm')
library;

import 'package:process_run/cmd_run.dart' show runCmd;
import 'package:process_run/src/dartbin_cmd.dart';
import 'package:test/test.dart';

void main() {
  group('dartbin_cmd_verbose', () {
    test('all', () async {
      expect((await runCmd(PubCmd(['--help']), verbose: true)).exitCode, 0);
    });
  });
}
