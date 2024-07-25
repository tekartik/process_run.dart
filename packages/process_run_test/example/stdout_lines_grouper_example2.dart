import 'package:process_run/stdio.dart';

Future<void> writeCount(int count) async {
  stdout.writeln('Counting to $count');
  for (var i = 0; i < count; i++) {
    stdout.writeln('${i + 1}');
    await Future<void>.delayed(Duration(milliseconds: 500));
  }
}

Future<void> main() async {
  stdout.writeln('Counting 2,1');
  shellStdioLinesGrouper.runZoned(() async {
    await Future<void>.delayed(Duration(milliseconds: 500));
    await writeCount(2);
  });
  shellStdioLinesGrouper.runZoned(() async {
    await Future<void>.delayed(Duration(milliseconds: 250));
    await writeCount(1);
  });
}
