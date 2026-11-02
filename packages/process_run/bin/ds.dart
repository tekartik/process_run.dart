import 'package:process_run/src/bin/shell/shell.dart' as shell;

/// ds, the process_run shell helper.
///
/// - `dart install process_run` (or `dart pub global activate process_run`)
///   puts `ds` on the PATH.
/// - `dart run process_run:ds` runs it from a project (`process_run:shell`
///   still works).
Future<void> main(List<String> arguments) => shell.main(arguments);
