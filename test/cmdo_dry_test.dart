library tekartik_cmdo.test.cmdo_dry_test;

import 'cmdo_test_common.dart';
import 'cmdo_test_.dart' as _test;

void main() {
  //_io.debugCmdoIo = true;
  group('io', () {
    _test.defineTests(dry);
  });
}
