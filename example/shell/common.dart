import 'package:process_run/shell.dart';

var ds = 'dart bin/shell.dart';

var env = ShellEnvironment()..aliases['ds'] = 'dart bin/shell.dart';
var shell = Shell(environment: env);
