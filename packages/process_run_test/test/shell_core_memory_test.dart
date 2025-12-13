import 'package:process_run/utils/shell_context.dart';
import 'package:process_run_test/shell_core_test.dart';

Future<void> main() async {
  shellContextMemory.runZoned(() async {
    shellCoreTests();
  });
}
