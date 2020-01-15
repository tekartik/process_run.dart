import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:process_run/src/user_config.dart';
import 'package:test/test.dart';

void main() {
  group('src_user_config', () {
    test('dummy_file', () async {
      //print(a);
      var path = join('test', 'data', 'test_env1.yaml_dummy');
      var userConfig =
          getUserConfig(<String, String>{userEnvFilePathEnvKey: path});
      expect(userConfig.vars, {
        'TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH': path,
        'PATH': [
          if (getFlutterAncestorPath(dartSdkBinDirPath) != null)
            getFlutterAncestorPath(dartSdkBinDirPath),
          dartSdkBinDirPath
        ].join(Platform.isWindows ? ';' : ':')
      });
      expect(userConfig.paths, [
        if (getFlutterAncestorPath(dartSdkBinDirPath) != null)
          getFlutterAncestorPath(dartSdkBinDirPath),
        dartSdkBinDirPath
      ]);
    });
    test('simple', () async {
      //print(a);
      var path = join('test', 'data', 'test_env1.yaml');
      var userConfig =
          getUserConfig(<String, String>{userEnvFilePathEnvKey: path});
      expect(userConfig.vars, {
        'TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH': path,
        'test': '1',
        'PATH': [
          'my_path',
          if (getFlutterAncestorPath(dartSdkBinDirPath) != null)
            getFlutterAncestorPath(dartSdkBinDirPath),
          dartSdkBinDirPath
        ].join(Platform.isWindows ? ';' : ':')
      });
      expect(userConfig.paths, [
        'my_path',
        if (getFlutterAncestorPath(dartSdkBinDirPath) != null)
          getFlutterAncestorPath(dartSdkBinDirPath),
        dartSdkBinDirPath
      ]);
    });

    test('userLoadConfigFile', () async {
      userConfig = UserConfig();

      //print(a);
      var path = join('test', 'data', 'test_env1.yaml');
      userLoadEnvFile(path);
      expect(userConfig.vars, {'test': '1', 'PATH': 'my_path'});
      expect(userConfig.paths, ['my_path']);
      userLoadEnvFile(path);
      // pointing out current bad (or expected hehavior when loading multiple files
      // TODO fix by compating the first items
      expect(userConfig.vars, {'test': '1', 'PATH': 'my_path'});
      expect(userConfig.paths, ['my_path']);
    });

    test('userLoadConfigMap', () async {
      userConfig = UserConfig();

      //print(a);
      userLoadConfigMap({
        'vars': {'test': '1'}
      });
      expect(userConfig.vars, {'test': '1', 'PATH': ''});
      expect(userConfig.paths, []);
      userLoadConfigMap({
        'path': ['my_path']
      });
      expect(userConfig.vars, {'test': '1', 'PATH': 'my_path'});
      expect(userConfig.paths, ['my_path']);
    });

    test('userLoadConfigMap(path)', () async {
      userConfig = UserConfig();

      userLoadConfigMap({
        'path': ['my_path']
      });
      expect(userConfig.vars, {'PATH': 'my_path'});
      expect(userConfig.paths, ['my_path']);
      userLoadConfigMap({
        'path': ['my_path']
      });
      expect(userConfig.vars, {'PATH': 'my_path'});
      expect(userConfig.paths, ['my_path']);
      userLoadConfigMap({
        'path': ['other_path']
      });
      expect(userConfig.vars, {
        'PATH': ['other_path', 'my_path'].join(envPathSeparator)
      });
      expect(userConfig.paths, ['other_path', 'my_path']);
      userLoadConfigMap({
        'path': ['other_path']
      });
      expect(userConfig.vars, {
        'PATH': ['other_path', 'my_path'].join(envPathSeparator)
      });
      expect(userConfig.paths, ['other_path', 'my_path']);
      userLoadConfigMap({'path': []});
      expect(userConfig.vars, {
        'PATH': ['other_path', 'my_path'].join(envPathSeparator)
      });
      expect(userConfig.paths, ['other_path', 'my_path']);
      userLoadConfigMap({
        'path': ['my_path']
      });
      expect(userConfig.paths, ['my_path', 'other_path', 'my_path']);
    });

    test('loadFromMap', () async {
      var config = loadFromMap({
        'var': {'test': 1}
      });
      expect(config.paths, []);
      expect(config.vars, {'test': '1'});
    });

    test('flutter ancestor', () async {
      expect(getFlutterAncestorPath(join('bin', 'cache', 'dart-sdk', 'bin')),
          'bin');
      expect(
          getFlutterAncestorPath(
              join('flutter', 'bin', 'cache', 'dart-sdk', 'bin')),
          join('flutter', 'bin'));
    });
  });
}
