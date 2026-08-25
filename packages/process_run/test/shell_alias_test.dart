@TestOn('vm')
library;

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/io/io.dart';
import 'package:process_run/src/io/user_shell_alias_io.dart';
import 'package:process_run/src/shell.dart' show ProcessRunShellTestExt;
import 'package:process_run/src/shell_alias.dart';
import 'package:test/test.dart';

/// Aliases used by the fake user shell (bash) alias resolver.
var _fakeLinuxShellAliases = <String, String>{};

ShellCommand _resolveAliases(String command, Map<String, String> aliases) =>
    resolveShellCommandAliases(ShellCommand.parse(command), aliases);

void main() {
  group('resolveShellCommandAliases', () {
    test('no alias', () {
      expect(
        _resolveAliases('echo hello', {}),
        ShellCommand('echo', ['hello']),
      );
      expect(
        _resolveAliases('echo hello', {'other': 'dummy'}),
        ShellCommand('echo', ['hello']),
      );
    });
    test('simple', () {
      expect(
        _resolveAliases('a1', {'a1': 'echo'}),
        ShellCommand('echo', <String>[]),
      );
      // The alias arguments are prepended to the command arguments
      expect(
        _resolveAliases('a1 world', {'a1': 'echo hello'}),
        ShellCommand('echo', ['hello', 'world']),
      );
    });
    test('quoted', () {
      expect(
        _resolveAliases('a1 world', {'a1': 'echo "hello you"'}),
        ShellCommand('echo', ['hello you', 'world']),
      );
    });
    test('nested', () {
      expect(
        _resolveAliases('a1 third', {'a1': 'a2 first', 'a2': 'echo second'}),
        ShellCommand('echo', ['second', 'first', 'third']),
      );
    });
    test('self referencing', () {
      // Like in bash, an alias is only expanded once
      expect(
        _resolveAliases('ls dir', {'ls': 'ls --color'}),
        ShellCommand('ls', ['--color', 'dir']),
      );
    });
    test('circular', () {
      expect(
        _resolveAliases('a1', {'a1': 'a2', 'a2': 'a1'}),
        ShellCommand('a1', <String>[]),
      );
    });
    test('empty alias', () {
      expect(
        _resolveAliases('a1 arg', {'a1': ''}),
        ShellCommand('a1', ['arg']),
      );
    });
    test('alias on arguments only', () {
      // Only the executable is resolved
      expect(
        _resolveAliases('echo a1', {'a1': 'dummy'}),
        ShellCommand('echo', ['a1']),
      );
    });
  });

  group('parseUserShellAliasDefinition', () {
    test('bash', () {
      expect(parseUserShellAliasDefinition("alias ll='ls -alF'"), 'ls -alF');
      expect(
        parseUserShellAliasDefinition("alias ll='ls -alF'", name: 'll'),
        'ls -alF',
      );
      // Another alias (or garbage written by the sourced rc files)
      expect(
        parseUserShellAliasDefinition("alias la='ls -A'", name: 'll'),
        isNull,
      );
    });
    test('zsh/dash', () {
      // zsh and dash `alias <name>` do not print the `alias ` prefix
      expect(
        parseUserShellAliasDefinition("ll='ls -alF'", name: 'll'),
        'ls -alF',
      );
    });
    test('not quoted', () {
      expect(parseUserShellAliasDefinition('ll=ls', name: 'll'), 'ls');
      expect(
        parseUserShellAliasDefinition('ll=ls -alF', name: 'll'),
        'ls -alF',
      );
    });
    test('escaped single quote (bash/zsh)', () {
      // bash prints an embedded `'` as `'\''`
      expect(
        parseUserShellAliasDefinition(
          "alias say='echo '\\''hi'\\'''",
          name: 'say',
        ),
        "echo 'hi'",
      );
    });
    test('escaped single quote (dash/ash)', () {
      // dash prints an embedded `'` as `'"'"'`
      expect(
        parseUserShellAliasDefinition(
          'say=\'echo \'"\'"\'hi\'"\'"',
          name: 'say',
        ),
        "echo 'hi'",
      );
    });
    test('invalid', () {
      expect(parseUserShellAliasDefinition(''), isNull);
      expect(parseUserShellAliasDefinition('some random output'), isNull);
      expect(parseUserShellAliasDefinition('=dummy'), isNull);
      expect(parseUserShellAliasDefinition('alias ll='), isNull);
      // Unbalanced quotes, the raw value is used
      expect(parseUserShellAliasDefinition("ll='ls", name: 'll'), "'ls");
    });
  });

  group('userShellAliasShellPath', () {
    var existingOverride = userShellAliasShellPathOverride;
    var existingEnvironment = platformEnvironment;
    tearDown(() {
      userShellAliasShellPathOverride = existingOverride;
      platformEnvironment = existingEnvironment;
    });
    test('from SHELL', () {
      platformEnvironment = {'SHELL': '/bin/zsh'};
      expect(userShellAliasShellPath, '/bin/zsh');
      platformEnvironment = {'SHELL': '/bin/dash'};
      expect(userShellAliasShellPath, '/bin/dash');
    });
    test('no SHELL defaults to null', () {
      platformEnvironment = <String, String>{};
      expect(userShellAliasShellPath, null);
      platformEnvironment = {'SHELL': ''};
      expect(userShellAliasShellPath, null);
    });
    test('unsupported shell', () {
      // We don't guess using another shell, the user aliases would be
      // defined somewhere else.
      platformEnvironment = {'SHELL': '/usr/bin/fish'};
      expect(userShellAliasShellPath, isNull);
      platformEnvironment = {'SHELL': '/usr/bin/nushell'};
      expect(userShellAliasShellPath, isNull);
    });
    test('override', () {
      platformEnvironment = {'SHELL': '/usr/bin/fish'};
      userShellAliasShellPathOverride = '/bin/bash';
      expect(userShellAliasShellPath, '/bin/bash');
    });
  });

  group('resolveShellCommandUserShellAlias', () {
    setUp(() {
      _fakeLinuxShellAliases = {'ll': 'ls -alF'};
      debugUserShellAliasResolver = (name) => _fakeLinuxShellAliases[name];
    });
    tearDown(() {
      debugUserShellAliasResolver = null;
    });
    test('found', () {
      expect(
        resolveShellCommandUserShellAlias(ShellCommand('ll', ['dir'])),
        ShellCommand('ls', ['-alF', 'dir']),
      );
    });
    test('not found', () {
      expect(resolveShellCommandUserShellAlias(ShellCommand('la', [])), isNull);
    });
    test('path executable is never an alias', () {
      expect(
        resolveShellCommandUserShellAlias(ShellCommand(join('bin', 'll'), [])),
        isNull,
      );
      expect(resolveShellCommandUserShellAlias(ShellCommand('', [])), isNull);
    });
  });

  group('Shell.resolveExecutedCommand', () {
    setUp(() {
      // Never spawn a real bash during the tests
      _fakeLinuxShellAliases = <String, String>{};
      debugUserShellAliasResolver = (name) => _fakeLinuxShellAliases[name];
    });
    tearDown(() {
      debugUserShellAliasResolver = null;
    });

    /// A shell with no path so that nothing but the aliases is resolved.
    Shell newShell(Map<String, String> aliases) => Shell(
      environment: ShellEnvironment.empty()..aliases.addAll(aliases),
      includeParentEnvironment: false,
    );

    test('process_run alias', () {
      var shell = newShell({'a1': 'echo hello'});
      expect(
        shell.resolveExecutedCommand(ShellCommand.parse('a1 world')),
        ShellCommand('echo', ['hello', 'world']),
      );
    });
    test('process_run nested alias', () {
      var shell = newShell({'a1': 'a2 first', 'a2': 'echo second'});
      expect(
        shell.resolveExecutedCommand(ShellCommand.parse('a1 third')),
        ShellCommand('echo', ['second', 'first', 'third']),
      );
    });
    test('user shell alias fallback', () {
      _fakeLinuxShellAliases = {'ll': 'ls -alF'};
      var shell = newShell({});
      expect(
        shell.resolveExecutedCommand(ShellCommand.parse('ll dir')),
        ShellCommand('ls', ['-alF', 'dir']),
      );
    });
    test('process_run alias wins over the user shell alias', () {
      _fakeLinuxShellAliases = {'ll': 'ls -alF'};
      var shell = newShell({'ll': 'echo mine'});
      expect(
        shell.resolveExecutedCommand(ShellCommand.parse('ll dir')),
        ShellCommand('echo', ['mine', 'dir']),
      );
    });
    test('user shell alias on the resolved alias', () {
      // The process_run alias is resolved first, its executable is then
      // resolved using the user shell aliases.
      _fakeLinuxShellAliases = {'ll': 'ls -alF'};
      var shell = newShell({'a1': 'll first'});
      expect(
        shell.resolveExecutedCommand(ShellCommand.parse('a1 second')),
        ShellCommand('ls', ['-alF', 'first', 'second']),
      );
    });
    test('unknown command is left as is', () {
      var shell = newShell({});
      expect(
        shell.resolveExecutedCommand(
          ShellCommand.parse('tk_test_dummy_command arg'),
        ),
        ShellCommand('tk_test_dummy_command', ['arg']),
      );
    });
  });

  group('userShellFindAliasSync', () {
    // Linux/macOS only for now.
    var dir = join('.dart_tool', 'process_run', 'test', 'linux_alias');

    /// Aliases written in the shell configuration file, using the POSIX
    /// escaping (`'\''` for an embedded single quote).
    var rcContent = [
      r"alias tk_test_alias='echo tk_hello'",
      r"alias tk_test_quoted='echo '\''hi'\'''",
      '',
    ].join('\n');

    /// Test a shell, skipped when it is not installed.
    void testShell(
      String shell, {
      required String rcFileName,
      required Map<String, String> Function(String home) environment,
    }) {
      test(shell, () async {
        var shellPath = whichSync(shell);
        if (shellPath == null) {
          markTestSkipped('$shell not installed');
          return;
        }
        var home = absolute(join(dir, shell));
        await Directory(home).create(recursive: true);
        await File(join(home, rcFileName)).writeAsString(rcContent);
        var env = environment(home);
        expect(
          userShellFindAliasSync(
            'tk_test_alias',
            shell: shellPath,
            environment: env,
          ),
          'echo tk_hello',
        );
        // Whichever the shell escaping style is
        expect(
          userShellFindAliasSync(
            'tk_test_quoted',
            shell: shellPath,
            environment: env,
          ),
          "echo 'hi'",
        );
        expect(
          userShellFindAliasSync(
            'tk_test_missing_alias',
            shell: shellPath,
            environment: env,
          ),
          isNull,
        );
      }, skip: userShellAliasEnabled ? false : 'linux/macOS only');
    }

    // bash reads `$HOME/.bashrc` when interactive
    testShell(
      'bash',
      rcFileName: '.bashrc',
      environment: (home) => {'HOME': home},
    );
    // zsh reads `$ZDOTDIR/.zshrc` (`$HOME` when not set) when interactive
    testShell(
      'zsh',
      rcFileName: '.zshrc',
      environment: (home) => {'HOME': home, 'ZDOTDIR': home},
    );
    // dash/ash read the file pointed by `$ENV` when interactive
    testShell(
      'dash',
      rcFileName: 'env.sh',
      environment: (home) => {'ENV': join(home, 'env.sh')},
    );

    test('unsupported shell', () {
      // fish and co: no lookup at all, `shell` resolves to null
      var existing = platformEnvironment;
      try {
        platformEnvironment = {'SHELL': '/usr/bin/fish'};
        expect(userShellFindAliasSync('tk_test_alias'), isNull);
      } finally {
        platformEnvironment = existing;
      }
    });
    test('invalid name', () {
      // Would be handled as an option by the `alias` builtin
      expect(userShellFindAliasSync('', shell: 'bash'), isNull);
      expect(userShellFindAliasSync('-a', shell: 'bash'), isNull);
    });
    test('missing shell', () {
      expect(
        userShellFindAliasSync('tk_test_alias', shell: 'tk_dummy_missing_sh'),
        isNull,
      );
    });
  });
}
