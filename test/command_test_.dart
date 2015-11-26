library command.test.command_test_;

import 'test_common.dart';

void main() => defineTests(dry);

void defineTests(CommandExecutor executor) {
  test('throw bad exe', () async {
    var err;
    try {
      print(await executor.runCmd(testCommandThrows.clone()..connectIo));
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull);
  });

  test('nothrow bad exe', () async {
    CommandResult result = await executor.runCmd(testCommandThrows.clone()
      ..throwException = false
      ..connectIo = false);

    expect(result.err, isNull);
    expect(result.out, isNull);
    expect(result.exitCode, isNull);
    expect(result.exception, isNotNull);
  });
}
