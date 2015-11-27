library process_run.dartbin;

import 'dart:io';
import 'package:path/path.dart';

String _dartExecutable;

///
/// Get dart vm either from executable or using the which command
///
String get dartExecutable {
  if (_dartExecutable == null) {
    _dartExecutable = Platform.resolvedExecutable;
  }
  return _dartExecutable;
}

String get _dartbinDirPath => dirname(dartExecutable);

/// For a dart binary (pub, dart2js, dartfmt...)
List<String> dartbinCmdArguments(String cmd, List<String> args) {
  // clone it
  args = new List.from(args);
  args.insert(0, join(_dartbinDirPath, 'snapshots', '${cmd}.dart.snapshot'));
  return args;
}

/// dartfmt command
List<String> dartfmtArguments(List<String> args) =>
    dartbinCmdArguments('dartfmt', args);

/// dartanalysze
List<String> dartanalyzerArguments(List<String> args) =>
    dartbinCmdArguments('dartanalyzer', args);

/// dart2js
List<String> dart2jsArguments(List<String> args) =>
    dartbinCmdArguments('dart2js', args);

/// dartdoc
List<String> dartdocArguments(List<String> args) =>
    dartbinCmdArguments('dartdoc', args);

/// pub
List<String> pubArguments(List<String> args) =>
    dartbinCmdArguments('pub', args);
