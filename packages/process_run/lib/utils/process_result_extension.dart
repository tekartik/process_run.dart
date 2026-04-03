import 'package:process_run/src/io/io.dart';
import 'package:process_run/src/process_cmd.dart';
import 'package:process_run/src/shell_bytes_controller.dart';
import 'package:process_run/src/shell_common.dart';
import 'package:process_run/src/shell_process_result.dart';

import '../shell.dart';

/// run response helper.
extension ProcessRunProcessResultsExt on List<ProcessResult> {
  ShellProcessResults get _shellProcessResults {
    if (this is ProcessResultInternalList) {
      return (this as ProcessResultInternalList).shellProcessResults;
    }
    return Shell().shellProcessResults(this);
  }

  /// Join the out lines for a quick string access.
  String get outText => _shellProcessResults.outText;

  /// Join the out lines for a quick string access.
  String get errText => _shellProcessResults.errText;

  /// Out line lists
  Iterable<String> get outLines => _shellProcessResults.outLines;

  /// Line lists
  Iterable<String> get errLines => _shellProcessResults.errLines;
}

/// run response helper.
extension ProcessRunFutureProcessResultsExt on Future<List<ProcessResult>> {
  /// Similar to the `|` on linux it allows to pipe the stdout
  /// of the ran commands as stdin to the next command.
  Future<List<ProcessResult>> pipe(String script) async {
    var results = await this;
    if (results is ProcessResultInternalList) {
      var shellResults = results.shellProcessResults;
      var output = shellResults.stdoutAsUint8List;
      var shell = shellResults.shell;
      var stdinController = ShellUint8ListController();
      stdinController.sink.add(output);
      var newShell = shell.cloneWithOptions(
        shell.options.clone(stdin: stdinController.stream),
      );
      newShell = shell.cloneWithOptions(shell.options.clone());
      try {
        var newResults = await newShell.run(script);
        return newResults;
      } finally {
        stdinController.close();
      }
    }
    throw UnsupportedError(
      'Invalid results type: ${results.runtimeType}, expected ProcessResultInternalList',
    );
  }
}

/// run response helper.
extension ProcessRunProcessResultExt on ProcessResult {
  /// Use a default shell to handle encoding if needed
  ShellProcessResult get _shellProcessResult =>
      Shell().shellProcessResult(this);

  /// Join the out lines for a quick string access.
  String get outText => _shellProcessResult.outText;

  /// Join the out lines for a quick string access.
  String get errText => _shellProcessResult.errText;

  /// Out line lists
  Iterable<String> get outLines => _shellProcessResult.outLines;

  /// Line lists
  Iterable<String> get errLines => _shellProcessResult.errLines;

  /// Process result debug string
  String toDebugString() {
    final sb = StringBuffer();
    sb.writeln('exitCode: ${this.exitCode}');
    if (stdIsNotEmpty(this.stdout)) {
      sb.writeln('out: ${this.stdout}');
    }
    if (stdIsNotEmpty(this.stderr)) {
      sb.writeln('err: ${this.stderr}');
    }
    return sb.toString();
  }
}

/// Process helper.
extension ProcessRunProcessExt on Process {
  /// Out lines stream
  Stream<String> get outLines => shellStreamLines(this.stdout);

  /// Err lines stream
  Stream<String> get errLines => shellStreamLines(this.stderr);
}
