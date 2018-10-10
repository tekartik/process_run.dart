import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/src/utils.dart';

import '../process_run.dart';
import 'process_cmd.dart';
import '../dartbin.dart';
import 'common/import.dart';

String dartBinFileName = 'dart${Platform.isWindows ? '.exe' : ''}';

@Deprecated('Use DartCmd instead')
ProcessCmd dartCmd(List<String> arguments) => DartCmd(arguments);

@Deprecated('Use DartFmtCmd instead')
ProcessCmd dartfmtCmd(List<String> args) => DartFmtCmd(args);

@Deprecated('Use DartAnalyzerCmd instead')
ProcessCmd dartanalyzerCmd(List<String> args) => DartAnalyzerCmd(args);

@Deprecated('Use Dart2JsCmd instead')
ProcessCmd dart2jsCmd(List<String> args) => Dart2JsCmd(args);

@Deprecated('Use DartDocCmd instead')
ProcessCmd dartdocCmd(List<String> args) => DartDocCmd(args);

@Deprecated('Use DartDevcCmd instead')
ProcessCmd dartdevcCmd(List<String> args) => DartDevcCmd(args);

@Deprecated('Use PubCmd instead')
ProcessCmd pubCmd(List<String> args) => PubCmd(args);

/// Call dart executable
class DartCmd extends _DartBinCmd {
  DartCmd(List<String> arguments) : super(dartBinFileName, arguments);
}

/// dartfmt command
class DartFmtCmd extends _DartBinCmd {
  DartFmtCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dartfmt'), arguments);
}

/// dartanalyzer
class DartAnalyzerCmd extends _DartBinCmd {
  DartAnalyzerCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dartanalyzer'), arguments);
}

/// dart2js
class Dart2JsCmd extends _DartBinCmd {
  Dart2JsCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dart2js'), arguments);
}

/// dartdoc
class DartDocCmd extends _DartBinCmd {
  DartDocCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dartdoc'), arguments);
}

/// dartdevc
class DartDevcCmd extends _DartBinCmd {
  DartDevcCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dartdevc'), arguments);
}

/// pub
class PubCmd extends _DartBinCmd {
  PubCmd(List<String> arguments)
      : super(getShellCmdBinFileName('pub'), arguments);
}

class DartDevkCmd extends _DartBinCmd {
  DartDevkCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dartdevk'), arguments);
}

class _DartBinCmd extends ProcessCmd {
  final String binName;
  _DartBinCmd(this.binName, List<String> arguments)
      : super(join(dartSdkBinDirPath, binName), arguments);

  @override
  String toString() => executableArgumentsToString(binName, arguments);
}
