import 'package:process_run/shell.dart';

import '../echo.dart';
import 'common.dart';

// Shell with hello command and sharedStdIn
var echoAndPromptShell = Shell(environment: echoEnv, stdin: sharedStdIn);

Future<void> main() async {
  await echoAndPromptShell.run('''
# Wait for input
write "Enter some text and Press enter"
prompt
write "Enter some text and Press enter again"
prompt
write "Third time"
prompt
''');

  // Create a new shell
  var echoEnv = ShellEnvironment()..aliases.addAll(commonAliases);
  echoAndPromptShell = Shell(environment: echoEnv, stdin: sharedStdIn);
  await echoAndPromptShell.run('''
# Wait for input
write "Third time"
prompt
write "Last time"
prompt

''');
  await sharedStdIn.terminate();
}
