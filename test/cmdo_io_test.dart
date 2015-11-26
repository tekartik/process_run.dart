@TestOn("vm")
library tekartik_cmdo.test.cmdo_io_test;

import 'cmdo_io_test_common.dart';
import 'cmdo_test.dart' as _test;

void main() {
  //_io.debugCmdoIo = true;
  group('io', () {
    _test.defineTests(io);

    test('run', () async {
      var input =
          new CommandInput(executable: dartVmBin, arguments: ['--version']);
      CommandResult result = await io.run(input);
      expect(result.output.err.first.toLowerCase(), contains("dart"));
      expect(result.output.err.first.toLowerCase(), contains("version"));
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
    });
  });
}
