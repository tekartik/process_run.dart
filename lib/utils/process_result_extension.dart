import 'dart:convert';
import 'dart:io';

/// run response helper.
extension ProcessRunProcessResultsExt on List<ProcessResult> {
  Iterable<String> _outTextsToLines(Iterable<String> out) =>
      out.expand((element) => LineSplitter.split(element));

  /// Out line lists
  Iterable<String> get outLines =>
      _outTextsToLines(map((result) => result.stdout.toString()));

  /// Line lists
  Iterable<String> get errLines =>
      _outTextsToLines(map((result) => result.stderr.toString()));
}
