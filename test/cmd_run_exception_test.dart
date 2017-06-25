@TestOn("vm")

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart';
import 'dart:io';

void main() {
  group('runCmdException', () {
    test('wrong directory', () async {
      // Should get something like
      // $ /usr/lib/dart/bin/dart version
      // ProcessException: No such file or directory
      // Command: /usr/lib/dart/bin/dart version
      // $ /usr/lib/dart/bin/dart version
      // workingDirectory: /dummy
      try {
        await runCmd(dartCmd(['version'])..workingDirectory = '/dummy');
        fail('should fail');
      } catch (e) {
        expect(e, new isInstanceOf<ProcessException>());
      }
    });
  });
}
