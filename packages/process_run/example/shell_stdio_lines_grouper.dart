import 'package:process_run/shell.dart';
import 'package:process_run/stdio.dart';
import '../test/src/compile_echo.dart';

void main() async {
  var echo = await compileEchoExample();

  var options = ShellOptions(
      verbose: true, environment: ShellEnvironment()..aliases['echo'] = echo);

  Future<List<ProcessResult>> printHello123Slow() async {
    var shell = Shell(options: options);
    return await shell.run('''
echo --wait 100 --stdout hello1 --write-line
echo --wait 100 --stdout hello2 --write-line
''');
  }

  var stdio = shellStdioLinesGrouper;
  await Future.wait<List<ProcessResult>>([
    stdio.runZoned(() => printHello123Slow()),
    stdio.runZoned(() => printHello123Slow())
  ]);
}
