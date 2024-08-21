@TestOn('vm')
library;

import 'package:process_run/utils/shell_bin_command.dart';
import 'package:test/test.dart';

void main() {
  test('basic', () {
    var cmd = ShellBinCommand(name: 'test');
    expect(cmd.name, 'test');
    cmd.parse(['--verbose']);
    expect(cmd.verbose, isTrue);
    cmd.parse([]);
    expect(cmd.verbose, isFalse);
  });
}
