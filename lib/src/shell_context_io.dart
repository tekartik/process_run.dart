import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart' as ds;
import 'package:process_run/src/shell_common.dart';
import 'package:process_run/src/shell_common_io.dart';
import 'package:process_run/src/shell_context_common.dart';
import 'package:process_run/src/shell_environment.dart' as io;
import 'package:process_run/src/shell_environment_common.dart';

class ShellContextIo implements ShellContext {
  @override
  ShellEnvironment get shellEnvironment =>
      io.ShellEnvironment(environment: ds.shellEnvironment);

  @override
  p.Context get path => p.context;

  @override
  Future<String?> which(String command,
          {ShellEnvironment? environment,
          bool includeParentEnvironment = true}) =>
      ds.which(command,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment);

  @override
  Encoding get encoding => systemEncoding;

  @override
  ShellIo newShell(
      {ShellOptions? options,
      ShellEnvironment? environment,
      bool includeParentEnvironment = true}) {
    return ShellIo(
        shellContextIo: this,
        options: options,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment);
  }
}
