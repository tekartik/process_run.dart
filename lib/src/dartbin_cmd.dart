import 'package:path/path.dart';

import '../process_run.dart';
import 'process_cmd.dart';
import '../dartbin.dart';
import 'common/import.dart';

/// Dart command
ProcessCmd dartCmd(List<String> arguments) =>
    new _DartBinCmd('dart', arguments);

/// dartfmt command
ProcessCmd dartfmtCmd(List<String> args) => new _DartBinCmd('dartfmt', args);

/// dartanalyzer
ProcessCmd dartanalyzerCmd(List<String> args) =>
    new _DartBinCmd('dartanalyzer', args);

/// dart2js
ProcessCmd dart2jsCmd(List<String> args) => new _DartBinCmd('dart2js', args);

/// dartdoc
ProcessCmd dartdocCmd(List<String> args) => new _DartBinCmd('dartdoc', args);

/// dartdevc
ProcessCmd dartdevcCmd(List<String> args) => new _DartBinCmd('dartdevc', args);

/// pub
ProcessCmd pubCmd(List<String> args) => new _DartBinCmd('pub', args);

class _DartBinCmd extends ProcessCmd {
  final String binName;
  _DartBinCmd(this.binName, List<String> arguments)
      : super(join(dartSdkBinDirPath, binName), arguments);

  @override
  String toString() => executableArgumentsToString(binName, arguments);
}

class _DartCmd extends ProcessCmd {
  _DartCmd(List<String> arguments) : super(dartExecutable, arguments);

  @override
  String toString() => executableArgumentsToString('dart', arguments);
}
