import 'dart:convert';
import 'dart:io';

import 'package:process_run/src/lines_utils.dart';

/// run response helper.
extension ProcessRunProcessResultsExt on List<ProcessResult> {
  Iterable<String> _outTextsToLines(Iterable<String> out) =>
      out.expand((element) => LineSplitter.split(element));

  /// Join the out lines for a quick string access.
  String get outText => outLines.join('\n');

  /// Join the out lines for a quick string access.
  String get errText => errLines.join('\n');

  /// Out line lists
  Iterable<String> get outLines =>
      _outTextsToLines(map((result) => result.stdout.toString()));

  /// Line lists
  Iterable<String> get errLines =>
      _outTextsToLines(map((result) => result.stderr.toString()));
}

/// Process helper.
extension ProcessRunProcessExt on Process {
  /// Out lines stream
  Stream<String> get outLines => shellStreamLines(this.stdout);

  /// Err lines stream
  Stream<String> get errLines => shellStreamLines(this.stderr);
}
