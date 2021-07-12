import 'dart:io';

import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  print(Platform.operatingSystem);
  print(Platform.version);
  await shell.run('''
# Analyze code & format
dart pub global activate dart_style
dart pub global run dart_style:format -n --set-exit-if-changed bin example lib test tool

# Run tests
dart test
''');
}
