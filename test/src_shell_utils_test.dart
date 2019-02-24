import 'package:process_run/src/shell_utils.dart';
import 'package:test/test.dart';

void main() {
  test('scriptToCommands', () {
    expect(scriptToCommands(''), []);
    expect(scriptToCommands('\\'), ['\\']);
    expect(scriptToCommands(' e\n#\n # comment\nf \n '), ['e', 'f']);
  });

  test('environmentFilterOutVmOptions', () {
    var env = {
      'DART_VM_OPTIONS': '--pause-isolates-on-start --enable-vm-service:51156'
    };
    env = environmentFilterOutVmOptions(env);
    expect(env, {});
    env = {
      'DART_VM_OPTIONS': '--enable-vm-service:51156',
      'TEKARTIK_DART_VM_OPTIONS': '--profile'
    };
    env = environmentFilterOutVmOptions(env);
    expect(env, {
      'TEKARTIK_DART_VM_OPTIONS': '--profile',
      'DART_VM_OPTIONS': '--profile'
    });
  });

  test('shellSplit', () {
    // We differ from io implementation
    expect(shellSplit(r'\'), [r'\']);
    expect(shellSplit('Hello  world'), ['Hello', 'world']);
    expect(shellSplit('"Hello  world"'), ['Hello  world']);
    expect(shellSplit("'Hello  world'"), ['Hello  world']);
  });
  test('shellJoin', () {
    void _test(String command, {String expected}) {
      var parts = shellSplit(command);
      var joined = shellJoin(parts);
      expect(joined, expected ?? command, reason: parts.toString());
    }

    _test('foo');
    _test('foo bar');
    _test(r'\');
    _test('"foo bar"');
    _test("'foo bar'", expected: '"foo bar"');
  });
}
