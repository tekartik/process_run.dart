import 'dart:io';

/// run response helper.
extension ProcessRunProcessResultsExt on List<ProcessResult> {
  /// Out line lists
  Iterable<String> get outLines => map((result) => result.stdout.toString());

  /// Line lists
  Iterable<String> get errLines => map((result) => result.stderr.toString());
}
