@TestOn('vm')
library;

import 'dart:io';

import 'package:process_run/src/io/shell_words.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:test/test.dart';

void main() {
  group('shellSplitImpl', () {
    // POSIX behavior, tests from package:io.
    group('returns an empty list for', () {
      test('an empty string', () {
        expect(shellSplitImpl(''), isEmpty);
      });

      test('spaces', () {
        expect(shellSplitImpl('    '), isEmpty);
      });

      test('tabs', () {
        expect(shellSplitImpl('\t\t\t'), isEmpty);
      });

      test('newlines', () {
        expect(shellSplitImpl('\n\n\n'), isEmpty);
      });

      test('a comment', () {
        expect(shellSplitImpl('#foo bar baz'), isEmpty);
      });

      test('a mix', () {
        expect(shellSplitImpl(' \t\n# foo'), isEmpty);
      });
    });

    group('parses unquoted', () {
      test('a single token', () {
        expect(shellSplitImpl('foo'), ['foo']);
      });

      test('multiple tokens', () {
        expect(shellSplitImpl('foo bar baz'), ['foo', 'bar', 'baz']);
      });

      test('tokens separated by tabs', () {
        expect(shellSplitImpl('foo\tbar\tbaz'), ['foo', 'bar', 'baz']);
      });

      test('tokens separated by newlines', () {
        expect(shellSplitImpl('foo\nbar\nbaz'), ['foo', 'bar', 'baz']);
      });

      test('a token after whitespace', () {
        expect(shellSplitImpl(' \t\nfoo'), ['foo']);
      });

      test('a token before whitespace', () {
        expect(shellSplitImpl('foo \t\n'), ['foo']);
      });

      test('a token with a hash', () {
        expect(shellSplitImpl('foo#bar'), ['foo#bar']);
      });

      test('a token before a comment', () {
        expect(shellSplitImpl('foo #bar'), ['foo']);
      });

      test('dynamic shell features', () {
        expect(shellSplitImpl(r'foo $(bar baz)'), ['foo', r'$(bar', 'baz)']);
        expect(shellSplitImpl('foo `bar baz`'), ['foo', '`bar', 'baz`']);
        expect(shellSplitImpl(r'foo $bar | baz'), ['foo', r'$bar', '|', 'baz']);
      });
    });

    group('parses a backslash', () {
      test('before a normal character', () {
        expect(shellSplitImpl(r'foo\bar'), ['foobar']);
      });

      test('before a dynamic shell feature', () {
        expect(shellSplitImpl(r'foo\$bar'), [r'foo$bar']);
      });

      test('before a single quote', () {
        expect(shellSplitImpl(r"foo\'bar"), ["foo'bar"]);
      });

      test('before a double quote', () {
        expect(shellSplitImpl(r'foo\"bar'), ['foo"bar']);
      });

      test('before a space', () {
        expect(shellSplitImpl(r'foo\ bar'), ['foo bar']);
      });

      test('at the beginning of a token', () {
        expect(shellSplitImpl(r'\ foo'), [' foo']);
      });

      test('before whitespace followed by a hash', () {
        expect(shellSplitImpl(r'\ #foo'), [' #foo']);
      });

      test('before a newline in a token', () {
        expect(shellSplitImpl('foo\\\nbar'), ['foobar']);
      });

      test('before a newline outside a token', () {
        expect(shellSplitImpl('foo \\\n bar'), ['foo', 'bar']);
      });

      test('before a backslash', () {
        expect(shellSplitImpl(r'foo\\bar'), [r'foo\bar']);
      });

      test('in a windows path', () {
        // This is why shellSplitWindowsImpl exists.
        expect(shellSplitImpl(r'C:\Users\foo'), ['C:Usersfoo']);
        expect(shellSplitImpl(r'"C:\Users\foo"'), [r'C:\Users\foo']);
        expect(shellSplitImpl(r'"C:\\Users\\foo"'), [r'C:\Users\foo']);
      });
    });

    group('parses single quotes', () {
      test('that are empty', () {
        expect(shellSplitImpl("''"), ['']);
      });

      test('that contain normal characters', () {
        expect(shellSplitImpl("'foo'"), ['foo']);
      });

      test('that contain active characters', () {
        expect(shellSplitImpl("'\" \\#'"), [r'" \#']);
      });

      test('before a hash', () {
        expect(shellSplitImpl("''#foo"), ['#foo']);
      });

      test('inside a token', () {
        expect(shellSplitImpl("foo'bar baz'qux"), ['foobar bazqux']);
      });

      test('without a closing quote', () {
        expect(() => shellSplitImpl("'foo bar"), throwsFormatException);
      });

      test('escaped single quote idioms', () {
        // bash/zsh `alias` output: 'echo '\''hi'\'''
        expect(shellSplitImpl("'echo '\\''hi'\\'''"), ["echo 'hi'"]);
        // dash/ash `alias` output: 'echo '"'"'hi'"'"
        expect(shellSplitImpl('\'echo \'"\'"\'hi\'"\'"'), ["echo 'hi'"]);
      });
    });

    group('parses double quotes', () {
      test('that are empty', () {
        expect(shellSplitImpl('""'), ['']);
      });

      test('that contain normal characters', () {
        expect(shellSplitImpl('"foo"'), ['foo']);
      });

      test('that contain otherwise-active characters', () {
        expect(shellSplitImpl('"\' #"'), ["' #"]);
      });

      test('that contain escaped characters', () {
        expect(shellSplitImpl(r'"\$\`\"\\"'), [r'$`"\']);
      });

      test('that contain an escaped newline', () {
        expect(shellSplitImpl('"\\\n"'), ['']);
      });

      test("that contain a backslash that's not an escape", () {
        expect(shellSplitImpl(r'"f\oo"'), [r'f\oo']);
      });

      test('before a hash', () {
        expect(shellSplitImpl('""#foo'), ['#foo']);
      });

      test('inside a token', () {
        expect(shellSplitImpl('foo"bar baz"qux'), ['foobar bazqux']);
      });

      test('without a closing quote', () {
        expect(() => shellSplitImpl('"foo bar'), throwsFormatException);
        expect(() => shellSplitImpl(r'"foo bar\'), throwsFormatException);
      });
    });
  });

  group('shellSplitWindowsImpl', () {
    // Same as POSIX but a backslash is never an escape character (it is a
    // path separator on Windows).
    group('returns an empty list for', () {
      test('an empty string', () {
        expect(shellSplitWindowsImpl(''), isEmpty);
      });

      test('whitespaces', () {
        expect(shellSplitWindowsImpl('    '), isEmpty);
        expect(shellSplitWindowsImpl('\t\t\t'), isEmpty);
        expect(shellSplitWindowsImpl('\n\n\n'), isEmpty);
      });

      test('a comment', () {
        expect(shellSplitWindowsImpl('#foo bar baz'), isEmpty);
        expect(shellSplitWindowsImpl(' \t\n# foo'), isEmpty);
      });
    });

    group('parses unquoted', () {
      test('a single token', () {
        expect(shellSplitWindowsImpl('foo'), ['foo']);
      });

      test('multiple tokens', () {
        expect(shellSplitWindowsImpl('foo bar baz'), ['foo', 'bar', 'baz']);
        expect(shellSplitWindowsImpl('foo\tbar\tbaz'), ['foo', 'bar', 'baz']);
        expect(shellSplitWindowsImpl('foo\nbar\nbaz'), ['foo', 'bar', 'baz']);
      });

      test('a token surrounded by whitespace', () {
        expect(shellSplitWindowsImpl(' \t\nfoo \t\n'), ['foo']);
      });

      test('a token with a hash', () {
        expect(shellSplitWindowsImpl('foo#bar'), ['foo#bar']);
      });

      test('a token before a comment', () {
        expect(shellSplitWindowsImpl('foo #bar'), ['foo']);
      });

      test('dynamic shell features', () {
        expect(shellSplitWindowsImpl(r'foo $(bar baz)'), [
          'foo',
          r'$(bar',
          'baz)',
        ]);
        expect(shellSplitWindowsImpl(r'foo %bar% | baz'), [
          'foo',
          '%bar%',
          '|',
          'baz',
        ]);
      });
    });

    group('keeps a backslash', () {
      test('before a normal character', () {
        expect(shellSplitWindowsImpl(r'foo\bar'), [r'foo\bar']);
      });

      test('before a dollar', () {
        expect(shellSplitWindowsImpl(r'foo\$bar'), [r'foo\$bar']);
      });

      test('before a space', () {
        // Not an escape, the space still separates the tokens.
        expect(shellSplitWindowsImpl(r'foo\ bar'), [r'foo\', 'bar']);
      });

      test('before a newline', () {
        // No line continuation.
        expect(shellSplitWindowsImpl('foo\\\nbar'), [r'foo\', 'bar']);
      });

      test('before a backslash', () {
        expect(shellSplitWindowsImpl(r'foo\\bar'), [r'foo\\bar']);
      });

      test('at the end of a token', () {
        expect(shellSplitWindowsImpl(r'dir C:\'), ['dir', r'C:\']);
      });

      test('in a windows path', () {
        expect(shellSplitWindowsImpl(r'C:\Users\foo\bar.exe --version'), [
          r'C:\Users\foo\bar.exe',
          '--version',
        ]);
        expect(shellSplitWindowsImpl(r'"C:\Program Files\foo\bar.exe" -v'), [
          r'C:\Program Files\foo\bar.exe',
          '-v',
        ]);
        expect(shellSplitWindowsImpl(r"'C:\Program Files\foo\bar.exe' -v"), [
          r'C:\Program Files\foo\bar.exe',
          '-v',
        ]);
      });
    });

    group('parses single quotes', () {
      test('that are empty', () {
        expect(shellSplitWindowsImpl("''"), ['']);
      });

      test('that contain normal characters', () {
        expect(shellSplitWindowsImpl("'foo'"), ['foo']);
      });

      test('that contain active characters', () {
        expect(shellSplitWindowsImpl("'\" \\#'"), [r'" \#']);
      });

      test('before a hash', () {
        expect(shellSplitWindowsImpl("''#foo"), ['#foo']);
      });

      test('inside a token', () {
        expect(shellSplitWindowsImpl("foo'bar baz'qux"), ['foobar bazqux']);
      });

      test('without a closing quote', () {
        expect(() => shellSplitWindowsImpl("'foo bar"), throwsFormatException);
      });
    });

    group('parses double quotes', () {
      test('that are empty', () {
        expect(shellSplitWindowsImpl('""'), ['']);
      });

      test('that contain normal characters', () {
        expect(shellSplitWindowsImpl('"foo"'), ['foo']);
      });

      test('that contain otherwise-active characters', () {
        expect(shellSplitWindowsImpl('"\' #"'), ["' #"]);
      });

      test('that contain backslashes', () {
        // No escaping, the backslashes are kept as is.
        expect(shellSplitWindowsImpl(r'"\$\`"'), [r'\$\`']);
        expect(shellSplitWindowsImpl(r'"\\"'), [r'\\']);
        expect(shellSplitWindowsImpl(r'"f\oo"'), [r'f\oo']);
        expect(shellSplitWindowsImpl(r'"C:\dir\"'), [r'C:\dir\']);
      });

      test('that contain a newline', () {
        expect(shellSplitWindowsImpl('"\\\n"'), ['\\\n']);
      });

      test('that cannot contain an escaped double quote', () {
        // The backslash does not escape the double quote which closes the
        // token.
        expect(shellSplitWindowsImpl(r'"foo\" bar'), [r'foo\', 'bar']);
      });

      test('before a hash', () {
        expect(shellSplitWindowsImpl('""#foo'), ['#foo']);
      });

      test('inside a token', () {
        expect(shellSplitWindowsImpl('foo"bar baz"qux'), ['foobar bazqux']);
      });

      test('without a closing quote', () {
        expect(() => shellSplitWindowsImpl('"foo bar'), throwsFormatException);
        expect(
          () => shellSplitWindowsImpl(r'"foo bar\'),
          throwsFormatException,
        );
      });
    });
  });

  group('shellSplit', () {
    test('platform implementation', () {
      // Valid on both platforms but split differently.
      var command = r'"C:\dir" \foo';
      if (Platform.isWindows) {
        expect(shellSplit(command), shellSplitWindowsImpl(command));
        expect(shellSplit(command), [r'C:\dir', r'\foo']);
      } else {
        expect(shellSplit(command), shellSplitImpl(command));
        expect(shellSplit(command), [r'C:\dir', 'foo']);
      }
      // A trailing backslash inside double quotes is an escaped quote on
      // POSIX (unmatched quote) but a literal backslash on Windows.
      var windowsOnlyCommand = r'"C:\dir\" \foo';
      if (Platform.isWindows) {
        expect(shellSplit(windowsOnlyCommand), [r'C:\dir\', r'\foo']);
      } else {
        expect(() => shellSplit(windowsOnlyCommand), throwsFormatException);
      }
    });
  });
}
