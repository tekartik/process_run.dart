import 'package:process_run/utils/shell_context.dart';

Future<void> main() async {
  await shellContextMemory.runZoned(() async {});
}
