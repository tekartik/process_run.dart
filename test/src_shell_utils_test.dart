import 'package:process_run/dartbin.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:test/test.dart';

void main() {
  group('shell_utils', () {
    test('scriptToCommands', () {
      expect(scriptToCommands(''), []);
      // expect(scriptToCommands('\\'), ['\\']);
      expect(scriptToCommands(' e\n#\n # comment\nf \n '),
          ['e', '#', '# comment', 'f']);
    });

    test('isLineToBeContinued', () {
      expect(isLineToBeContinued(''), isFalse);
      expect(isLineToBeContinued('\\'), isTrue);
      expect(isLineToBeContinued('^'), isTrue);
      expect(isLineToBeContinued('\\'), isTrue);
      expect(isLineToBeContinued('a^'), isFalse);
      expect(isLineToBeContinued(' ^'), isTrue);
      expect(isLineToBeContinued('a ^'), isTrue);
      expect(isLineToBeContinued(' \\'), isTrue);
      expect(isLineToBeContinued('a\\'), isFalse);
      expect(isLineToBeContinued('a \\'), isTrue);
    });

    test('isLineComment', () {
      expect(isLineComment(''), isFalse);
      expect(isLineComment('a'), isFalse);
      expect(isLineComment('\\'), isFalse);
      expect(isLineComment('//'), isTrue);
      expect(isLineComment('//a'), isFalse);
      expect(isLineComment('// '), isTrue);
      expect(isLineComment('///'), isTrue);
      expect(isLineComment('///a'), isFalse);
      expect(isLineComment('/// '), isTrue);
      expect(isLineComment('#a'), isTrue);
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
      expect(
          shellSplit(
              'curl --location --request POST "https://postman-echo.com/post" --data "This is expected to be sent back as part of response body."'),
          [
            'curl',
            '--location',
            '--request',
            'POST',
            'https://postman-echo.com/post',
            '--data',
            'This is expected to be sent back as part of response body.'
          ]);
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

    test('no_env', () {
      expect(findExecutableSync('dart', []), isNull);
      expect(findExecutableSync('pub', []), isNull);

      expect(findExecutableSync('dart', [dartSdkBinDirPath]), dartExecutable);
      expect(findExecutableSync('pub', [dartSdkBinDirPath]), isNotNull);
    });

    test('various', () {
      expect(scriptToCommands('''
     a ^
     
     b
    '''), ['a', 'b']);
      expect(scriptToCommands('''
     a ^
     b
     
     c
    '''), ['a b', 'c']);
      expect(scriptToCommands('''
a ^
 "b" ^
 "c" d
e
    '''), ['a "b" "c" d', 'e']);
    });
  });
}
