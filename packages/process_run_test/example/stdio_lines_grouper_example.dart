import 'dart:async';

import 'package:process_run/stdio.dart';

Future<void> writeCount(int count) async {
  stdout.writeln('Counting to $count');
  for (var i = 0; i < count; i++) {
    if (i.isEven) {
      stderr.writeln('Error: ${i + 1}');
    } else {
      stdout.writeln('Info: ${i + 1}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}

Future<void> main() async {
  unawaited(
    shellStdioLinesGrouper.runZoned(() async {
      await writeCount(4);
    }),
  );

  unawaited(
    shellStdioLinesGrouper.runZoned(() async {
      await writeCount(10);
    }),
  );
}
