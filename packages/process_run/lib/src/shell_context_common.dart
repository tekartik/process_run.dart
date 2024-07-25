import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:process_run/src/shell_common.dart';

/// abstract shell context
abstract class ShellContext {
  /// Shell environment
  ShellEnvironment get shellEnvironment;

  /// Which command.
  Future<String?> which(String command,
      {ShellEnvironment? environment, bool includeParentEnvironment = true});

  /// Path context.
  p.Context get path;

  /// Default shell encoding (systemEncoding on iOS)
  Encoding get encoding;

  /// New shell must set itself as a shell Context, shell environement is
  /// no longer relevent.
  Shell newShell(
      {ShellOptions? options,
      @Deprecated('Use options') Map<String, String>? environment,
      @Deprecated('Use options') bool includeParentEnvironment = true});

  /// New shell environment
  ShellEnvironment newShellEnvironment({
    Map<String, String>? environment,
  });
}

/// Shell context mixin
mixin ShellContextMixin implements ShellContext {
  @override
  Encoding get encoding =>
      throw UnimplementedError('ShellContextMixin.encoding');
  @override
  Shell newShell(
      {ShellOptions? options,
      Map<String, String>? environment,
      bool includeParentEnvironment = true}) {
    throw UnimplementedError('ShellContext.newShell');
  }

  @override
  ShellEnvironment newShellEnvironment({Map<String, String>? environment}) {
    throw UnimplementedError('ShellContext.newShellEnvironment');
  }

  @override
  p.Context get path => throw UnimplementedError('ShellContext.path');

  @override
  ShellEnvironment get shellEnvironment =>
      throw UnimplementedError('ShellContext.shellEnvironment');

  @override
  Future<String?> which(String command,
      {ShellEnvironment? environment, bool includeParentEnvironment = true}) {
    throw UnimplementedError('ShellContext.which');
  }
}

/// In memory shell context.
class ShellContextMemory with ShellContextMixin implements ShellContext {
  @override
  Encoding get encoding => utf8;
}

/// In memory shell context.
final shellContextMemory = ShellContextMemory();
