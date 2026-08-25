import 'package:process_run/shell.dart';

/// To run after push.
Future<void> main() async {
  await run(
    'dart pub global activate --source git https://github.com/tekartik/process_run.dart.git --git-path packages/process_run',
  );
}
