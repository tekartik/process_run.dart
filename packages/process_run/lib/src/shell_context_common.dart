import 'dart:async' as async;
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/src/env_utils.dart';
import 'package:process_run/src/shell.dart';
import 'package:process_run/src/shell_common.dart';
import 'package:process_run/src/shell_environment.dart';

/// Platform info
abstract class ShellContextPlatform {
  /// Is linux
  bool get isLinux;

  /// Is macos
  bool get isMacOS;

  /// Is windows
  bool get isWindows;

  /// Is android
  bool get isAndroid;

  /// Is ios
  bool get isIOS;

  /// Is web
  bool get isWeb;

  /// None - no platform detected
  bool get isNone;
  static ShellContextPlatform? __current;

  /// Current cached platform
  factory ShellContextPlatform() {
    return __current ??= ShellContextPlatform._current();
  }

  /// None
  factory ShellContextPlatform.none() {
    return _ShellContextPlatform(isNone: true);
  }

  /// Linux
  factory ShellContextPlatform.linux() {
    return _ShellContextPlatform(isLinux: true);
  }

  /// MacOS
  factory ShellContextPlatform.macos() {
    return _ShellContextPlatform(isMacOS: true);
  }

  /// Windows
  factory ShellContextPlatform.windows() {
    return _ShellContextPlatform(isWindows: true);
  }

  /// Android
  factory ShellContextPlatform.android() {
    return _ShellContextPlatform(isAndroid: true);
  }

  /// iOS
  factory ShellContextPlatform.ios() {
    return _ShellContextPlatform(isIOS: true);
  }

  /// Web
  factory ShellContextPlatform.web() {
    return _ShellContextPlatform(isWeb: true);
  }

  /// Detect current platform
  factory ShellContextPlatform._current() {
    if (kDartIsWeb) {
      return _ShellContextPlatform(isWeb: true);
    }
    if (Platform.isLinux) {
      return _ShellContextPlatform(isLinux: true);
    }
    if (Platform.isMacOS) {
      return _ShellContextPlatform(isMacOS: true);
    }
    if (Platform.isWindows) {
      return _ShellContextPlatform(isWindows: true);
    }
    if (Platform.isAndroid) {
      return _ShellContextPlatform(isAndroid: true);
    }
    if (Platform.isIOS) {
      return _ShellContextPlatform(isIOS: true);
    }
    return _ShellContextPlatform();
  }
}

class _ShellContextPlatform
    with ShellContextPlatformDefaultMixin
    implements ShellContextPlatform {
  @override
  final bool isLinux;
  @override
  final bool isMacOS;
  @override
  final bool isWindows;
  @override
  final bool isAndroid;
  @override
  final bool isIOS;
  @override
  final bool isWeb;
  @override
  final bool isNone;

  _ShellContextPlatform({
    this.isLinux = false,
    this.isMacOS = false,
    this.isWindows = false,
    this.isAndroid = false,
    this.isIOS = false,
    this.isWeb = false,
    bool? isNone,
  }) : isNone =
           isNone ??
           !(isLinux || isMacOS || isWindows || isAndroid || isIOS || isWeb);
}

/// Default mixin
mixin ShellContextPlatformDefaultMixin implements ShellContextPlatform {
  @override
  bool get isLinux => false;
  @override
  bool get isMacOS => false;
  @override
  bool get isWindows => false;
  @override
  bool get isAndroid => false;
  @override
  bool get isIOS => false;
  @override
  bool get isWeb => false;
  @override
  bool get isNone => false;
}

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
  Shell shell({ShellOptions? options});

  /// New shell environment
  ShellEnvironment newShellEnvironment({Map<String, String>? environment});

  /// Platform info
  ShellContextPlatform get platform;

  /// Close the context
  Future<void> close();
}

/// Must not have the default mixin
class _ShellContextWithDelegate implements ShellContext {
  final ShellContext delegate;

  _ShellContextWithDelegate(this.delegate, {required this.shellEnvironment});

  @override
  Encoding get encoding => delegate.encoding;

  @override
  Shell shell({ShellOptions? options}) => delegate.shell(options: options);

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

  @override
  Future<void> close() async {
    await delegate.close();
  }

  @override
  ShellContextPlatform get platform => delegate.platform;
}

/// Shell context mixin
mixin ShellContextMixin implements ShellContext {
  @override
  Future<void> close() async {}
  @override
  Encoding get encoding =>
      throw UnimplementedError('ShellContextMixin.encoding');
  @override
  Shell shell({ShellOptions? options}) {
    throw UnimplementedError('ShellContext.shell');
  }

  @override
  ShellContextPlatform get platform => ShellContextPlatform();

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
ShellContext? get zonedShellContextOrNull => _inZoneCount > 0
    ? async.Zone.current[_shellContextZoneVar] as ShellContext?
    : null;
const _shellContextZoneVar = #tekartik_shell_context;
