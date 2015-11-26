library tekartik_cmdo.dartbin_utils;

import 'dart:io';
import 'package:path/path.dart';
import 'cmdo.dart';

String _dartVmBin;

bool _debug = false;

///
/// Get dart vm either from executable or using the which command
///
String get dartVmBin {
  if (_dartVmBin == null) {
    _dartVmBin = Platform.resolvedExecutable;
  }
  return _dartVmBin;
}

String get _dartBinDirPath => dirname(dartVmBin);

String get _dartVmBinExecutable => dartVmBin;

// Create a dart cmd
CommandInput dartCmd(List<String> arguments) =>
    commandInput(_dartVmBinExecutable, arguments);

// use dartCmd instead
@deprecated
CommandInput dartBinCmd(List<String> arguments) => dartCmd(arguments);

List<String> _dartCmdArguments(String cmd, List<String> args) {
  // clone it
  args = new List.from(args);
  args.insert(0, join(_dartBinDirPath, 'snapshots', '${cmd}.dart.snapshot'));
  return args;
}

List<String> dartFmtArguments(List<String> args) =>
    _dartCmdArguments('dartfmt', args);
CommandInput dartFmtCmd(List<String> args) => dartCmd(dartFmtArguments(args));
List<String> dartAnalyzerArguments(List<String> args) =>
    _dartCmdArguments('dartanalyzer', args);
CommandInput dartAnalyzerCmd(List<String> args) =>
    dartCmd(dartAnalyzerArguments(args));
List<String> dart2JsArguments(List<String> args) =>
    _dartCmdArguments('dart2js', args);
CommandInput dart2JsCmd(List<String> args) => dartCmd(dart2JsArguments(args));
List<String> pubArguments(List<String> args) => _dartCmdArguments('pub', args);
CommandInput pubCmd(List<String> args) => dartCmd(pubArguments(args));
