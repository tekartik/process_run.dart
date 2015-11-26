library command.test.command_test;

import 'command_test_common.dart';

void main() => defineTests(dry);

void defineTests(CommandExecutor command) {
  test('throw bad exe', () async {
    var err;
    try {
      print(await command.runCmd(testCommandThrows.clone()..connectIo));
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull);
  });

  test('nothrow bad exe', () async {
    CommandResult result = await command.runCmd(testCommandThrows.clone()
      ..throwException = false
      ..connectIo = false);

    expect(result.err, isNull);
    expect(result.out, isNull);
    expect(result.exitCode, isNull);
    expect(result.exception, isNotNull);
  });
}
