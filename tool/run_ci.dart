import 'dart:io';

import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  print(Platform.operatingSystem);
  print(Platform.version);
  await shell.run('''
# Analyze code
dart pub global run dart_style:format -n --set-exit-if-changed bin example lib test tool

# Formatting
dartfmt -n --set-exit-if-changed .

# Run tests
pub run test -p vm

''');
}
