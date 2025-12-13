import 'dart:async';

import 'package:process_run/stdio.dart';

Future<void> writeCount(int count) async {
  stdout.writeln('Counting to $count');
  for (var i = 0; i < count; i++) {
    stdout.writeln('${i + 1}');
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}

Future<void> main() async {
  stdout.writeln('Counting 2,5,10');
  unawaited(
    shellStdioLinesGrouper.runZoned(() async {
      await writeCount(2);
    }),
  );
  unawaited(
    shellStdioLinesGrouper.runZoned(() async {
      await writeCount(5);
    }),
  );
  unawaited(
    shellStdioLinesGrouper.runZoned(() async {
      await writeCount(10);
    }),
  );
}
