@TestOn('vm')
library;

import 'package:process_run/process_run.dart';
import 'package:process_run/src/bin/shell/import.dart';
import 'package:process_run/src/stdio/stdio.dart';
import 'package:test/test.dart';

import 'src/compile_echo.dart';

void main() {
  group('shell_stdio_lines_grouper', () {
    test('hello12', () async {
      var echo = await compileEchoExample();

      var options = ShellOptions(
        verbose: false,
        environment: ShellEnvironment()..aliases['echo'] = echo,
      );
      var lines =
          (await Shell(options: options).run('echo --stdout test')).outLines;
      expect(lines, ['test']);
      /*
      var env = ShellEnvironment()
        // ..aliases['echo'] = 'dart run ${shellArgument(echoScriptPath)}';
        ..aliases['echo'] = echo;

      var options = ShellOptions(environment: env);
      */
      var shell = Shell(options: options);

      await shell.run('echo --stdout hello1');

      /*
      var options = ShellOptions(verbose: true, environment: env);
      */
      Future<List<ProcessResult>> printHello123Slow() async {
        var shell = Shell(options: options);
        return await shell.run('''
echo --wait 100 --stdout hello1
echo --wait 100 --stdout hello2
''');
      }

      // await printHello123Slow();

      var stdio = shellStdioLinesGrouper;
      await Future.wait<List<ProcessResult>>([
        stdio.runZoned(() => printHello123Slow()),
        printHello123Slow(),
      ]);

      var inMemoryStderr = InMemoryIOSink(StdioStreamType.err);
      var isMemoryStdout = InMemoryIOSink(StdioStreamType.out);
      stdio = ShellStdioLinesGrouper(
        stderr: inMemoryStderr,
        stdout: isMemoryStdout,
      );
      await Future.wait<List<ProcessResult>>([
        stdio.runZoned(() => printHello123Slow()),
        printHello123Slow(),
      ]);
      // Not working yet
      // expect(isMemoryStdout.lines, ['hello1', 'hello2', 'hello1', 'hello2', 'hello1', 'hello2']);
    });
    test('in memory stdout/stderr', () async {
      var inMemoryStderr = InMemoryIOSink(StdioStreamType.err);
      var inMemoryStdout = InMemoryIOSink(StdioStreamType.out);
      var stdio = ShellStdioLinesGrouper(
        stderr: inMemoryStderr,
        stdout: inMemoryStdout,
      );
      await stdio.runZoned(() async {
        stdout.writeln('test1');
        stderr.writeln('test2');
        stdout.writeln('test3');
      });
      expect(inMemoryStdout.lines, ['test1', 'test3']);
      expect(inMemoryStderr.lines, ['test2']);
    });

    test('empty lines', () async {
      var inMemoryStderr = InMemoryIOSink(StdioStreamType.err);
      var inMemoryStdout = InMemoryIOSink(StdioStreamType.out);
      var stdio = ShellStdioLinesGrouper(
        stderr: inMemoryStderr,
        stdout: inMemoryStdout,
      );
      await stdio.runZoned(() async {
        stdout.writeln('test1');
        stdout.writeln('');
        stdout.writeln('test2');
      });
      expect(inMemoryStdout.lines, ['test1', '', 'test2']);
    });

    test('CRLF', () async {
      var inMemoryStderr = InMemoryIOSink(StdioStreamType.err);
      var inMemoryStdout = InMemoryIOSink(StdioStreamType.out);
      var stdio = ShellStdioLinesGrouper(
        stderr: inMemoryStderr,
        stdout: inMemoryStdout,
      );
      await stdio.runZoned(() async {
        stdout.write('test1\r\n');
        stdout.write('test2\r');
        stdout.write('test3\n');
        stdout.writeln('test4');
      });
      expect(inMemoryStdout.lines, ['test1', 'test2', 'test3', 'test4']);
    });

    test('last lines', () async {
      var inMemoryStderr = InMemoryIOSink(StdioStreamType.err);
      var inMemoryStdout = InMemoryIOSink(StdioStreamType.out);
      var stdio = ShellStdioLinesGrouper(
        stderr: inMemoryStderr,
        stdout: inMemoryStdout,
      );
      await stdio.runZoned(() async {
        stdout.writeln('test1');
        stdout.writeln('');
        stdout.write('test');
        stdout.write('2');
      });
      expect(inMemoryStdout.lines, ['test1', '', 'test2']);
    });

    test('last done before first', () async {
      var inMemoryStderr = InMemoryIOSink(StdioStreamType.err);
      var inMemoryStdout = InMemoryIOSink(StdioStreamType.out);
      var stdio = ShellStdioLinesGrouper(
        stderr: inMemoryStderr,
        stdout: inMemoryStdout,
      );
      var futures = <Future>[];
      futures.add(
        stdio.runZoned(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          stdout.writeln('test1');
        }),
      );
      futures.add(
        stdio.runZoned(() async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          stdout.writeln('test2');
        }),
      );
      futures.add(
        stdio.runZoned(() async {
          stdout.writeln('test3');
        }),
      );
      await Future.wait(futures);
      expect(inMemoryStdout.lines, ['test1', 'test2', 'test3']);
    });

    test('first done before last', () async {
      var inMemoryStderr = InMemoryIOSink(StdioStreamType.err);
      var inMemoryStdout = InMemoryIOSink(StdioStreamType.out);
      var stdio = ShellStdioLinesGrouper(
        stderr: inMemoryStderr,
        stdout: inMemoryStdout,
      );
      var futures = <Future>[];
      futures.add(
        stdio.runZoned(() async {
          stdout.writeln('test1');
        }),
      );
      futures.add(
        stdio.runZoned(() async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          stdout.writeln('test2');
        }),
      );
      futures.add(
        stdio.runZoned(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          stdout.writeln('test3');
        }),
      );
      await Future.wait(futures);
      expect(inMemoryStdout.lines, ['test1', 'test2', 'test3']);
    });
  });
}
