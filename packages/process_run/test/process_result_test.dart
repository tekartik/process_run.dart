import 'dart:io';
import 'package:process_run/utils/process_result_extension.dart';
import 'package:test/test.dart';

void main() {
  group('ProcessResult extension', () {
    test('outLines', () {
      var result = ProcessResult(0, 0, 'line1\nline2', '');
      expect(result.outLines, ['line1', 'line2']);
      expect(result.outText, 'line1\nline2');
    });

    test('errLines', () {
      var result = ProcessResult(0, 0, '', 'err1\nerr2');
      expect(result.errLines, ['err1', 'err2']);
      expect(result.errText, 'err1\nerr2');
    });
  });

  group('ProcessResults extension', () {
    test('outLines', () {
      var results = [
        ProcessResult(0, 0, 'line1\nline2', ''),
        ProcessResult(0, 0, 'line3', ''),
      ];
      expect(results.outLines, ['line1', 'line2', 'line3']);
      expect(results.outText, 'line1\nline2\nline3');
    });

    test('errLines', () {
      var results = [
        ProcessResult(0, 0, '', 'err1'),
        ProcessResult(0, 0, '', 'err2\nerr3'),
      ];
      expect(results.errLines, ['err1', 'err2', 'err3']);
      expect(results.errText, 'err1\nerr2\nerr3');
    });
  });
}
