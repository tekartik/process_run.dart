import 'package:process_run/shell.dart';

/// Similar to the command:
/// echo example | ls
Future<void> main(List<String> args) async {
  await run('echo example').pipe('ls');
}
