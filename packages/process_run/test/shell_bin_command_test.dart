@TestOn('vm')
library;

import 'dart:async';

import 'package:process_run/utils/shell_bin_command.dart';
import 'package:test/test.dart';

class _SubCommand extends ShellBinCommand {
  _SubCommand() : super(name: 'sub');

  bool? ranVerbose;

  @override
  FutureOr<bool> onRun() {
    ranVerbose = verbose;
    return true;
  }
}

class _MainCommand extends ShellBinCommand {
  _MainCommand() : super(name: 'main') {
    addCommand(sub);
  }

  final sub = _SubCommand();
}

void main() {
  test('basic', () {
    var cmd = ShellBinCommand(name: 'test');
    expect(cmd.name, 'test');
    cmd.parse(['--verbose']);
    expect(cmd.verbose, isTrue);
    cmd.parse([]);
    expect(cmd.verbose, isFalse);
  });
  test('sub command verbose', () async {
    var cmd = _MainCommand();
    await cmd.parseAndRun(['sub']);
    expect(cmd.sub.ranVerbose, isFalse);

    cmd = _MainCommand();
    await cmd.parseAndRun(['-v', 'sub']);
    expect(cmd.sub.ranVerbose, isTrue);

    cmd = _MainCommand();
    await cmd.parseAndRun(['sub', '-v']);
    expect(cmd.sub.ranVerbose, isTrue);
  });
}
