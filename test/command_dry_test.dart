library command.test.command_dry_test;

import 'command_test_common.dart';
import 'command_test_.dart' as _test;

void main() {
  //_io.debugCmdoIo = true;
  group('dry', () {
    _test.defineTests(dry);
  });
}
