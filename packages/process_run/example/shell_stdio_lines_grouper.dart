import 'package:process_run/shell.dart';
import 'package:process_run/stdio.dart';
import '../test/src/compile_echo.dart';

void main() async {
  var echo = await compileEchoExample();

  var options = ShellOptions(
    verbose: true,
    environment: ShellEnvironment()..aliases['echo'] = echo,
  );

  Future<void> printHello12345Slow() async {
    var shell = Shell(options: options);

    await shell.run('''
echo --wait 100 --stdout hello1 --write-line
echo --wait 100 --stdout hello2 --write-line
echo --wait 100 --stderr hello3 --write-line
''');
    stdout.writeln('hello4');
    stderr.writeln('hello5');
  }

  var stdio = shellStdioLinesGrouper;
  await Future.wait<void>([
    stdio.runZoned(() => printHello12345Slow()),
    stdio.runZoned(() => printHello12345Slow()),
  ]);
}
