@TestOn("vm")
library tekartik_cmdo.test.cmdo_io_test;

import 'cmdo_io_test_common.dart';
import 'cmdo_test_.dart' as _test;
import 'package:cmdo/dartbin.dart';

void main() {
  //_io.debugCmdoIo = true;
  group('io', () {
    _test.defineTests(io);

    group('async', () {
      test('throw bad exe', () async {
        var err;
        try {
          await io.runInputAsync(testCommandThrows.clone());
        } catch (e) {
          err = e;
        }
        expect(err, isNotNull);
      });

      test('nothrow bad exe', () async {
        CommandResult result = await io
            .runInputAsync(testCommandThrows.clone()..throwException = false);

        expect(result.err, isNull);
        expect(result.out, isNull);
        expect(result.exitCode, isNull);
        expect(result.exception, isNotNull);
      });

      test('dart_version', () async {
        CommandInput input = commandInput(dartVmBin, ['--version']);
        CommandResult result = await io.runInput(input);
        expect(result.output.errLines.first.toLowerCase(), contains("dart"));
        expect(result.output.errLines.first.toLowerCase(), contains("version"));

        result = await io.runInputAsync(input);
        expect(result.output.errLines.first.toLowerCase(), contains("dart"));
        expect(result.output.errLines.first.toLowerCase(), contains("version"));
      });
    });
  });
}
