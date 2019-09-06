import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/common/constant.dart';
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
        'PATH': '${dartSdkBinDirPath}'
      });
      expect(userConfig.paths, [dartSdkBinDirPath]);
    });
    test('simple', () async {
      //print(a);
      var path = join('test', 'data', 'test_env1.yaml');
      var userConfig =
          getUserConfig(<String, String>{userEnvFilePathEnvKey: path});
      expect(userConfig.vars, {
        'TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH': path,
        'test': '1',
        'PATH': ['my_path', '${dartSdkBinDirPath}']
            .join(Platform.isWindows ? ';' : ':')
      });
      expect(userConfig.paths, ['my_path', dartSdkBinDirPath]);
    });
  });
}
