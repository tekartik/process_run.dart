import 'common.dart';

Future<void> main() async {
  await shell.run('''
# Change the env file location
ds env var set TEKARTIK_PROCESS_RUN_LOCAL_ENV_FILE_PATH .local/ds_env.yaml

''');
}
