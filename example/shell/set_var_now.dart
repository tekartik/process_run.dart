import 'common.dart';

Future<void> main() async {
  var now = DateTime.now().toUtc().toIso8601String();
  await shell.run('''
# Change the env file location
ds env var set TEST_VAR_NOW $now

ds env var dump

''');
}
