import 'package:process_run/stdio.dart';

Future<void> writeCount(int count) async {
  stderr.writeln('Counting to $count');
  for (var i = 0; i < count; i++) {
    stderr.writeln('${i + 1}');
    await Future<void>.delayed(Duration(milliseconds: 500));
  }
}

Future<void> main() async {
  shellStdioLinesGrouper.runZoned(() async {
    await writeCount(2);
  });
  shellStdioLinesGrouper.runZoned(() async {
    await writeCount(10);
  });
}
