library tekartik_cmdo.test.cmdo_test;

import 'cmdo_test_common.dart';

void main() => defineTests(dry);

void defineTests(CommandExecutor cmdo) {
  test('throw bad exe', () async {
    var err;
    try {
      await cmdo.run(testCommandThrows);
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull);
  });

  test('nothrow bad exe', () async {
    CommandResult result =
        await cmdo.run(testCommandThrows.clone()..throwException = false);

    expect(result.output, isNull);
  });
}
