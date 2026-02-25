library;

import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void main() {
  test('ShellException', () {
    var exception = ShellException('test', null);
    expect(exception.toString(), 'ShellException(test)');
    expect(exception.toDebugString(), 'message: test\n');
    exception = ShellException(
      'test',
      ProcessResult(1, 2, 'testout', 'testerr'),
    );

    expect(exception.toString(), 'ShellException(test)');
    expect(exception.toDebugString(), '''
message: test
exitCode: 2
out: testout
err: testerr
''');
    exception = ShellException(
      'test',
      null,
      command: ProcessCmd('testcmd', [], workingDirectory: 'testdir'),
    );

    expect(exception.toString(), 'ShellException(test)');
    expect(exception.toDebugString(), '''
message: test
dir: testdir
cmd: testcmd
''');

    // Partial info (not stdout/stderr no directory)
    exception = ShellException(
      'test',
      ProcessResult(1, 2, null, null),
      command: ProcessCmd('testcmd', []),
    );

    expect(exception.toString(), 'ShellException(test)');
    expect(exception.toDebugString(), '''
message: test
cmd: testcmd
exitCode: 2
''');
  });
}
