import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

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
