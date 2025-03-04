import 'dart:async' as async;
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:process_run/src/shell.dart';
import 'package:process_run/src/shell_common.dart';
import 'package:process_run/src/shell_environment.dart';

/// abstract shell context
abstract class ShellContext {
  /// Shell environment
  ShellEnvironment get shellEnvironment;

  /// Which command.
  Future<String?> which(
    String command, {
    ShellEnvironment? environment,
    bool includeParentEnvironment = true,
  });

  /// Path context.
  p.Context get path;

  /// Default shell encoding (systemEncoding on iOS)
  Encoding get encoding;

  /// New shell must set itself as a shell Context, shell environement is
  /// no longer relevent.
  Shell newShell({ShellOptions? options});

  /// New shell environment
  ShellEnvironment newShellEnvironment({Map<String, String>? environment});
}

class _ShellContextWithDelegate implements ShellContext {
  final ShellContext delegate;

  _ShellContextWithDelegate(this.delegate, {required this.shellEnvironment});

  @override
  Encoding get encoding => delegate.encoding;

  @override
  Shell newShell({ShellOptions? options}) =>
      delegate.newShell(options: options);

  @override
  ShellEnvironment newShellEnvironment({Map<String, String>? environment}) =>
      delegate.newShellEnvironment(environment: environment);

  @override
  p.Context get path => delegate.path;

  @override
  final ShellEnvironment shellEnvironment;

  @override
  async.Future<String?> which(
    String command, {
    ShellEnvironment? environment,
    bool includeParentEnvironment = true,
  }) {
    return delegate.which(
      command,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
    );
  }
}

/// Shell context mixin
mixin ShellContextMixin implements ShellContext {
  @override
  Encoding get encoding =>
      throw UnimplementedError('ShellContextMixin.encoding');
  @override
  Shell newShell({
    ShellOptions? options,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
  }) {
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
  Future<String?> which(
    String command, {
    ShellEnvironment? environment,
    bool includeParentEnvironment = true,
  }) {
    throw UnimplementedError('ShellContext.which');
  }
}

/// Global zone count for fast access
int _inZoneCount = 0;

/// Shell context extension
extension ShellContextExt on ShellContext {
  /// Run in a zone,
  Future<T> runZoned<T>(Future<T> Function() action) => _runZonedImpl(action);

  /// Run in a zone, grouping lines
  Future<T> _runZonedImpl<T>(Future<T> Function() action) async {
    try {
      _inZoneCount++;
      return await async.runZoned(() async {
        try {
          return await action();
        } finally {}
      }, zoneValues: {_shellContextZoneVar: this});
    } finally {
      _inZoneCount--;
    }
  }

  /// Copy with a new shell environment
  ShellContext copyWith({ShellEnvironment? shellEnvironment}) {
    return _ShellContextWithDelegate(
      this,
      shellEnvironment: shellEnvironment ?? this.shellEnvironment,
    );
  }
}

/// Overriden shell stdio if any.
ShellContext? get zonedShellContextOrNull =>
    _inZoneCount > 0
        ? async.Zone.current[_shellContextZoneVar] as ShellContext?
        : null;
const _shellContextZoneVar = #tekartik_shell_context;

/// In memory shell context.
class ShellContextMemory with ShellContextMixin implements ShellContext {
  @override
  Encoding get encoding => utf8;
}

/// In memory shell context.
final shellContextMemory = ShellContextMemory();
