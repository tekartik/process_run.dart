import 'dart:convert';

import 'package:process_run/src/stdio/stdio.dart';
import 'package:test/test.dart';

void main() {
  group('shell_stdio', () {
    test('StdioStream', () {
      // ignore: unused_local_variable
      var shellStreamer = ShellOutputLinesStreamer();
      shellStreamer.out.add(utf8.encode('hi'));
      shellStreamer.err.add(utf8.encode('error'));

      shellStreamer.close();
    });
  });
}
