@TestOn('vm')
library;

import 'package:process_run/src/stdio/stdio.dart';
import 'package:test/test.dart';

void main() {
  group('IOSink', () {
    test('memory', () async {
      // ignore: close_sinks
      var inMemoryStdout = InMemoryIOSink(StdioStreamType.out);
      inMemoryStdout.writeln('test');
      expect(inMemoryStdout.lines, ['test']);
    });
  });
}
