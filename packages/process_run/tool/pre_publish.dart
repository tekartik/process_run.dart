import 'package:process_run/shell.dart';

void main() async {
  await run('dart pub run build_runner build --delete-conflicting-outputs');
}
