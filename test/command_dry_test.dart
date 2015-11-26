library command.test.command_dry_test;

import 'test_common.dart';
import 'command_test_.dart' as _test;

void main() {
  //_io.debugCommand = true;
  group('dry', () {
    _test.defineTests(dry);
  });
}
