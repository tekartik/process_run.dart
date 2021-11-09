import 'package:process_run/src/shell_common.dart';

Future<void> main() async {
  var shell = Shell();
  var result = await shell.run('echo Hello');
  print(result);
  print(await which('ls'));
}
