import 'dart:io';

import 'package:path/path.dart';

import '../process_run.dart';
import 'process_cmd.dart';
import '../dartbin.dart';
import 'common/import.dart';

String dartBinFileName = 'dart${Platform.isWindows ? '.exe' : ''}';
String _getShellCmdBinFileName(String command) =>
    '$command${Platform.isWindows ? '.bat' : ''}';

/// Dart command
ProcessCmd dartCmd(List<String> arguments) =>
    new _DartBinCmd(dartBinFileName, arguments);

/// dartfmt command
ProcessCmd dartfmtCmd(List<String> args) =>
    new _DartBinCmd(_getShellCmdBinFileName('dartfmt'), args);

/// dartanalyzer
ProcessCmd dartanalyzerCmd(List<String> args) =>
    new _DartBinCmd(_getShellCmdBinFileName('dartanalyzer'), args);

/// dart2js
ProcessCmd dart2jsCmd(List<String> args) =>
    new _DartBinCmd(_getShellCmdBinFileName('dart2js'), args);

/// dartdoc
ProcessCmd dartdocCmd(List<String> args) =>
    new _DartBinCmd(_getShellCmdBinFileName('dartdoc'), args);

/// dartdevc
ProcessCmd dartdevcCmd(List<String> args) =>
    new _DartBinCmd(_getShellCmdBinFileName('dartdevc'), args);

/// pub
ProcessCmd pubCmd(List<String> args) =>
    new _DartBinCmd(_getShellCmdBinFileName('pub'), args);

class _DartBinCmd extends ProcessCmd {
  final String binName;
  _DartBinCmd(this.binName, List<String> arguments)
      : super(join(dartSdkBinDirPath, binName), arguments);

  @override
  String toString() => executableArgumentsToString(binName, arguments);
}
