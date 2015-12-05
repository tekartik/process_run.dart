@TestOn("vm")
library command.test.process_run_test_;

import 'package:dev_test/test.dart';
import 'package:process_run/src/process_cmd.dart';

void main() {
  group('ProcessCmd', () {
    test('simple', () {
      ProcessCmd cmd = new ProcessCmd("a", []);
      expect(cmd.executable, "a");
    });
    test('equals', () {
      ProcessCmd cmd1 = new ProcessCmd("a", []);
      ProcessCmd cmd2 = new ProcessCmd("a", []);
      expect(cmd1, cmd2);
    });
  });
}
