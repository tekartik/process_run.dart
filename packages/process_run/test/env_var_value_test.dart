@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/user_config.dart';
import 'package:test/test.dart';

/// Values that a plain yaml scalar would not read back as the same string.
final _values = <String, String>{
  'V_COMMENT': '#x',
  'V_OCTAL': '007',
  'V_PADDED': ' padded ',
  'V_MAPPING': 'a: b',
  'V_EMPTY': '',
  'V_QUOTES': 'q"uo\'te \\ back',
  'V_NEWLINE': 'line1\nline2',
  'V_BOOL': 'true',
  'V_NULL': '~',
  'V_LIST': '[a, b]',
  'V_ALIAS': '*ref',
  'V_TAB': 'tab\tx',
  'V_UNICODE': 'é 😀',
};

void main() {
  group('env var value', () {
    late Directory dir;
    late Map<String, String> environment;
    late String userEnvFilePath;
    late String localEnvFilePath;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('process_run_env_var_');
      userEnvFilePath = join(dir.path, 'user_env.yaml');
      localEnvFilePath = join(dir.path, 'local_env.yaml');
      // Never the real user env file
      environment = {
        userEnvFilePathEnvKey: userEnvFilePath,
        localEnvFilePathEnvKey: localEnvFilePath,
      };
    });
    tearDown(() async {
      await dir.delete(recursive: true);
    });

    Shell newShell() => Shell(
      environment: environment,
      includeParentEnvironment: false,
      verbose: false,
    );

    for (var local in [false, true]) {
      test('round trip ${local ? 'local' : 'user'}', () async {
        var shell = newShell();
        for (var entry in _values.entries) {
          await shell.shellVarOverride(entry.key, entry.value, local: local);
        }
        // Read back from the file
        var vars = getUserConfig(environment).vars;
        for (var entry in _values.entries) {
          expect(vars[entry.key], entry.value, reason: entry.key);
        }
        var fileVars = loadFromPath(
          local ? localEnvFilePath : userEnvFilePath,
        ).vars;
        expect(fileVars, _values);

        // Delete keeps the other values
        await shell.shellVarOverride('V_MAPPING', null, local: local);
        vars = getUserConfig(environment).vars;
        expect(vars.containsKey('V_MAPPING'), isFalse);
        expect(vars['V_OCTAL'], '007');
      });
    }

    test('file written by older versions', () async {
      // Values were written as is before 1.4.0
      await File(userEnvFilePath).writeAsString('''
var:
  V_OCTAL: 007
  V_EMPTY:
  V_FLOAT: 1.50
  V_MAPPING: a: b
  V_PLAIN: plain value
alias:
  ll: ls -l
''');
      var config = loadFromPath(userEnvFilePath);
      expect(config.vars, {
        'V_OCTAL': '007',
        'V_EMPTY': '',
        'V_FLOAT': '1.50',
        'V_MAPPING': 'a: b',
        'V_PLAIN': 'plain value',
      });
      expect(config.aliases, {'ll': 'ls -l'});
    });
  });
}
