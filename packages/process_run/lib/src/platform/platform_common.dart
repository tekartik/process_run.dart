import 'package:meta/meta.dart';
import 'package:process_run/src/platform/platform.dart';
import 'package:process_run/src/shell_context_common.dart';

/// Global platform shell context, if any.
@internal
ShellContext? shellContextPlatformOrNull;

/// Set shell context before use, default to io on io, in memory otherwise.
set shellContext(ShellContext shellContext) =>
    shellContextPlatformOrNull = shellContext;

/// Internal use only.
@visibleForTesting
void clearShellContext() {
  shellContextPlatformOrNull = null;
}

/// Shell context for the current zone or platform
ShellContext get shellContext => zonedShellContextOrNull ?? shellContextDefault;
