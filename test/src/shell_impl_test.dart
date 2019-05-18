@TestOn("vm")
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/user_config.dart';
import 'package:test/test.dart';

void main() {
  group('Shell', () {
    test('user', () {
      if (Platform.isWindows) {
        expect(userHomePath, Platform.environment['USERPROFILE']);
        expect(userAppDataPath, Platform.environment['APPDATA']);
      } else {
        expect(userHomePath, Platform.environment['HOME']);
        expect(userAppDataPath, join(Platform.environment['HOME'], '.config'));
      }
    });

    test('userHomePath', () {
      try {
        shellEnvironment = <String, String>{userHomePathEnvKey: 'test'};
        expect(userHomePath, 'test');
      } finally {
        shellEnvironment = null;
      }
    });

    test('userAppDataPath', () {
      try {
        shellEnvironment = <String, String>{userAppDataPathEnvKey: 'test'}
          ..addAll(Platform.environment);
        expect(userAppDataPath, 'test');

        shellEnvironment = <String, String>{userHomePathEnvKey: 'test'};
        expect(userAppDataPath, join('test', '.config'));
      } finally {
        shellEnvironment = null;
      }
    });

    test('userEnvironment', () async {
      try {
        var filePath =
            join('.dart_tool', 'process_run', 'test', 'user_env', 'env.yaml');
        resetUserConfig();
        await Directory(dirname(filePath)).create(recursive: true);
        await File(filePath).writeAsString('''
        path: test
        var:
          _TEKARTIK_PROCESS_RUN_TEST: 1
        ''');
        shellEnvironment = <String, String>{userEnvFilePathEnvKey: filePath}
          ..addAll(Platform.environment);
        // expect(getUserEnvFilePath(shellEnvironment), filePath);
        expect(userPaths, ['test']);
        expect(userEnvironment['_TEKARTIK_PROCESS_RUN_TEST'], '1');

        resetUserConfig();
        await Directory(dirname(filePath)).create(recursive: true);
        await File(filePath).writeAsString('''
        
        path:
          - test
          - '~/test2'
        var:
          - _TEKARTIK_PROCESS_RUN_TEST: '~'
        ''');
        shellEnvironment = <String, String>{userEnvFilePathEnvKey: filePath}
          ..addAll(Platform.environment);
        // expect(getUserEnvFilePath(shellEnvironment), filePath);
        expect(userPaths, ['test', join(userHomePath, 'test2')]);
        expect(userEnvironment['_TEKARTIK_PROCESS_RUN_TEST'], '~');
      } finally {
        shellEnvironment = null;
      }
    });

    test('user env in shell', () async {
      try {
        var filePath = join('.dart_tool', 'process_run', 'test',
            'user_env_in_shell', 'env.yaml');
        resetUserConfig();
        await Directory(dirname(filePath)).create(recursive: true);
        await File(filePath).writeAsString('''
        path: test
        var:
          _TEKARTIK_PROCESS_RUN_TEST: 1
        ''', flush: true);
        shellEnvironment = <String, String>{userEnvFilePathEnvKey: filePath}
          ..addAll(Platform.environment);
        expect(userEnvironment['_TEKARTIK_PROCESS_RUN_TEST'], '1');

        var result = (await run('dart example/echo.dart --stdout-env PATH'))
            .first
            .stdout
            .toString()
            .trim();
        expect(result, isNotEmpty);

        result = (await run(
                'dart example/echo.dart --stdout-env _dummy_that_will_never_exist'))
            .first
            .stdout
            .toString()
            .trim();
        expect(result, isEmpty);

        result = (await run(
                'dart example/echo.dart --stdout-env _TEKARTIK_PROCESS_RUN_TEST'))
            .first
            .stdout
            .toString()
            .trim();
        expect(result, isEmpty);

        result = (await run(
                'dart example/echo.dart --stdout-env _TEKARTIK_PROCESS_RUN_TEST',
                environment: userEnvironment))
            .first
            .stdout
            .toString()
            .trim();
        expect(result, '1');
        result = (await run(
                'dart example/echo.dart --stdout-env _TEKARTIK_PROCESS_RUN_TEST',
                environment: <String, String>{
              '_TEKARTIK_PROCESS_RUN_TEST': '78910'
            }))
            .first
            .stdout
            .toString()
            .trim();
        expect(result, '78910');
      } finally {
        shellEnvironment = null;
      }
    });
  });
}
