@TestOn('vm')
library;

import 'dart:convert';

import 'package:process_run/shell.dart';
import 'package:process_run/src/common/import.dart';
import 'package:test/test.dart';

import 'src/compile_echo.dart';
import 'src/compile_streamer.dart';

void main() {
  group('ShellLinesController', () {
    late ShellEnvironment env;
    setUpAll(() async {
      env = ShellEnvironment()
        ..aliases['streamer'] = await compileStreamerExample()
        ..aliases['echo'] = await compileEchoExample();
    });
    test('stream all', () async {
      var ctlr = ShellLinesController();
      var lines = <String>[];
      ctlr.stream.listen((event) {
        lines.add(event);
      });
      var shell = Shell(environment: env, stdout: ctlr.sink, verbose: false);
      await shell.run('streamer --count 10000');
      expect(lines, hasLength(10000));
      ctlr.close();
    });
    test('stream some', () async {
      var ctlr = ShellLinesController();
      var lines = <String>[];
      var shell = Shell(environment: env, stdout: ctlr.sink, verbose: false);
      late StreamSubscription subscription;
      subscription = ctlr.stream.listen((event) {
        lines.add(event);
        if (lines.length >= 10000) {
          shell.kill();
          subscription.cancel();
        }
      });

      // Wait more than 30s
      try {
        await shell.run('streamer --timeout 60000');
      } catch (e) {
        // Should fail
      }
    }, timeout: const Timeout(Duration(milliseconds: 30000)));
    test('a line not in the encoding is kept', () async {
      var ctlr = ShellLinesController(encoding: utf8);
      var lines = ctlr.stream.toList();
      ctlr.sink.add([
        ...utf8.encode('ok\nbad '),
        0xff,
        ...utf8.encode('\nlast\n'),
      ]);
      ctlr.close();
      // It was dropped (and printed as bytes).
      expect(await lines, ['ok', 'bad \u{FFFD}', 'last']);
    });
    test('addError', () async {
      var ctlr = ShellLinesController();
      var completer = Completer<bool>();
      ctlr.stream.listen(
        (event) {
          fail('should not be called');
        },
        onError: (Object e) {
          expect(e, 'test');
          completer.complete(true);
        },
      );
      ctlr.sink.addError('test');

      await completer.future;
      ctlr.close();
    });
    test('shell error', () async {
      var ctlr = ShellLinesController();
      var completer = Completer<bool>();
      ctlr.stream.listen(
        (event) {},
        onError: (Object e) {
          var shellException = e as ShellException;
          expect(shellException.result!.exitCode, 1);
          //expect(e, 'test');
          completer.complete(true);
        },
      );
      var shell = Shell(stdout: ctlr.sink, environment: env);
      await shell
          .run('echo --exit-code 1')
          .then((_) => ctlr.close(), onError: ctlr.sink.addError);
      await completer.future;
    });
    test('shell stdin', () async {
      var ctlr = ShellLinesController();
      var inputController = ShellLinesController();
      var completer = Completer<bool>();
      ctlr.stream.listen((event) {
        if (event == 'stdin_done') {
          completer.complete(true);
        }
      });
      var shell = Shell(
        stdout: ctlr.sink,
        stdin: inputController.binaryStream,
        environment: env,
      );
      var done = shell.run('echo --stdin --write-line --verbose');
      inputController.writeln('stdin_done');
      inputController.close();
      await completer.future;
      await done;
    });
  });
}
