import 'package:process_run/shell.dart';

var ds = 'dart run bin/shell.dart';

var env = ShellEnvironment()..aliases['ds'] = 'dart run bin/shell.dart';
var shell = Shell(environment: env);
