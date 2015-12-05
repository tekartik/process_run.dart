library process_run.src.dartbin_cmd;

import 'package:process_run/cmd/process_cmd.dart';
import '../dartbin.dart';

/// Dart command
ProcessCmd dartCmd(List<String> arguments) =>
    processCmd(dartExecutable, arguments);

/// dartfmt command
ProcessCmd dartfmtCmd(List<String> args) => dartCmd(dartfmtArguments(args));

/// dartanalyzer
ProcessCmd dartanalyzerCmd(List<String> args) =>
    dartCmd(dartanalyzerArguments(args));

/// dart2js
ProcessCmd dart2jsCmd(List<String> args) => dartCmd(dart2jsArguments(args));

/// dartdoc
ProcessCmd dartdocCmd(List<String> args) => dartCmd(dartdocArguments(args));

/// pub
ProcessCmd pubCmd(List<String> args) => dartCmd(pubArguments(args));
