import 'dart:io';
import 'package:path/path.dart';
import 'package:process_run/src/common/dartbin.dart';

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

String get dartSdkDirPath => dirname(_dartbinDirPath);

String dartbinCmdSnapshot(String cmd) =>
    join(_dartbinDirPath, 'snapshots', '${cmd}.dart.snapshot');

/// For a dart binary (pub, dart2js, dartfmt...)
List<String> dartbinCmdArguments(String cmd, List<String> args) {
  // clone it
  args = new List.from(args);
  args.insert(0, dartbinCmdSnapshot(cmd));
  return args;
}

/// dartfmt command
List<String> dartfmtArguments(List<String> args) =>
    dartbinCmdArguments('dartfmt', args);

/// dartanalyzer
List<String> dartanalyzerArguments(List<String> args) =>
    dartbinCmdArguments('dartanalyzer', args);

/// dart2js
/// [libraryRoot] necessary and computed if not provided
List<String> dart2jsArguments(List<String> args, {String libraryRoot}) {
  List<String> dart2jsArgs = new List.from(args ?? []);
  if (libraryRoot == null) {
    libraryRoot = dartSdkDirPath;
  }
  dart2jsArgs.insertAll(0, ['--library-root=${libraryRoot}']);
  return dartbinCmdArguments('dart2js', dart2jsArgs);
}

/// dartdoc
List<String> dartdocArguments(List<String> args) {
  String cmd = 'dartdoc';
  return new List<String>.from(args)
    ..insertAll(0, [
      '--packages=${join(_dartbinDirPath, 'snapshots', 'resources', cmd, '.packages')}',
      dartbinCmdSnapshot(cmd)
    ]);
}

/// pub
List<String> pubArguments(List<String> args) =>
    dartbinCmdArguments(dartPubName, args);
