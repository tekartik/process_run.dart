import 'package:process_run/shell.dart';

var ds = 'dart bin/shell.dart';
Future<void> main() async {
  var env = ShellEnvironment();
  // Convenient in development alias to use non global version
  env.aliases['ds'] = 'dart bin/shell.dart';
  var shell = Shell(environment: env);
  await shell.run('''
# Version
ds --version

# Can be invoke in multiple ways
ds run echo Hello World
ds run 'echo Hello World'
pub run process_run:shell run echo Hello World

''');

//   {
//     await shell.run('''
// # once installed
// pub global activate process_run
// ds run
// ''');
//   }
}
