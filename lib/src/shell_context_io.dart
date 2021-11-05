import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart' as ds;
import 'package:process_run/src/shell_context_common.dart';
import 'package:process_run/src/shell_environment.dart';

class ShellContextIo implements ShellContext {
  @override
  ShellEnvironment get shellEnvironment =>
      asShellEnvironment(ds.shellEnvironment);

  @override
  p.Context get path => p.context;

  @override
  Future<String?> which(String command) => ds.which(command);

  @override
  Encoding get encoding => systemEncoding;
}
