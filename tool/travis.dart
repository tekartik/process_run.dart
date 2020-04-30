import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Future main() async {
  var shell = Shell();

  // Formatting change in 2.9 with hashbang first line
  if (dartVersion >= Version(2, 9, 0, pre: '0')) {
    await shell.run('''
    # Formatting
    dartfmt -n --set-exit-if-changed .
    ''');
  }

  print(Platform.version);
  await shell.run('''
# Analyze code
dartanalyzer --fatal-warnings --fatal-infos example lib tool test

# Run tests
pub run test -p vm -r expanded
pub run test -p vm -r expanded test/example_hex_utils_test_.dart

# Run tests using build_runner
pub run build_runner test -- -p vm -r expanded
''');
}
