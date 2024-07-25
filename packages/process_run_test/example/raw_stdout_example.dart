import 'dart:io';

void writeCount(int count) {
  stdout.writeln('Counting to $count');
  for (var i = 0; i < count; i++) {
    if (i.isEven) {
      stderr.writeln('Error: ${i + 1}');
    } else {
      stdout.writeln('Info: ${i + 1}');
    }
  }
}

Future<void> main() async {
  writeCount(2);
  writeCount(10);
}
