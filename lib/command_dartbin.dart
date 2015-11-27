library command.dartbin;

import 'dart:io';
import 'package:path/path.dart';
import 'command_common.dart';

String _dartVmBin;

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

/// Create a dart cmd
CommandInput dartCmd(List<String> arguments) =>
    command(_dartVmBinExecutable, arguments);

List<String> _dartbinCmdArguments(String cmd, List<String> args) {
  // clone it
  args = new List.from(args);
  args.insert(0, join(_dartBinDirPath, 'snapshots', '${cmd}.dart.snapshot'));
  return args;
}

List<String> _dartfmtArguments(List<String> args) =>
    _dartbinCmdArguments('dartfmt', args);

/// dartfmt command
CommandInput dartfmtCmd(List<String> args) => dartCmd(_dartfmtArguments(args));

List<String> _dartanalyzerArguments(List<String> args) =>
    _dartbinCmdArguments('dartanalyzer', args);
CommandInput dartanalyzerCmd(List<String> args) =>
    dartCmd(_dartanalyzerArguments(args));

List<String> _dart2jsArguments(List<String> args) =>
    _dartbinCmdArguments('dart2js', args);
CommandInput dart2jsCmd(List<String> args) => dartCmd(_dart2jsArguments(args));

List<String> dartdocArguments(List<String> args) =>
    _dartbinCmdArguments('dartdoc', args);
CommandInput dartdocCmd(List<String> args) => dartCmd(dartdocArguments(args));

List<String> pubArguments(List<String> args) =>
    _dartbinCmdArguments('pub', args);
CommandInput pubCmd(List<String> args) => dartCmd(pubArguments(args));
