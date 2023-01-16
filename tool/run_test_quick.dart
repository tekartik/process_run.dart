import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
# Analyze code
dart analyze --fatal-warnings --fatal-infos example lib tool test
dart format --set-exit-if-changed .

# Run tests
dart test -p vm
''');
}
