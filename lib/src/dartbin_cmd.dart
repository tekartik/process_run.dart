import '../process_run.dart';
import 'process_cmd.dart';
import '../dartbin.dart';
import 'common/import.dart';

/// Dart command
ProcessCmd dartCmd(List<String> arguments) => new _DartCmd(arguments);

/// dartfmt command
ProcessCmd dartfmtCmd(List<String> args) => dartCmd(dartfmtArguments(args));

/// dartanalyzer
ProcessCmd dartanalyzerCmd(List<String> args) =>
    dartCmd(dartanalyzerArguments(args));

/// dart2js
ProcessCmd dart2jsCmd(List<String> args) => dartCmd(dart2jsArguments(args));

/// dartdoc
ProcessCmd dartdocCmd(List<String> args) => dartCmd(dartdocArguments(args));

/// dartdevc
ProcessCmd dartdevcCmd(List<String> args) => dartCmd(dartdevcArguments(args));

class _DartCmd extends ProcessCmd {
  List<String> _originalArguments;

  _DartCmd(List<String> arguments) : super(dartExecutable, arguments);

  @override
  String toString() => executableArgumentsToString(dartName, arguments);
}

class _PubCmd extends ProcessCmd {
  List<String> _originalArguments;

  _PubCmd(List<String> arguments)
      : _originalArguments = arguments,
        super(dartExecutable, pubArguments(arguments));

  @override
  String toString() =>
      executableArgumentsToString(dartPubName, _originalArguments);
}

/// pub
ProcessCmd pubCmd(List<String> args) => new _PubCmd(args);
