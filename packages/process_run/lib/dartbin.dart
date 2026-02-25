/// Prefer using shell.
///
/// {@canonicalFor flutterbin_cmd.getFlutterBinChannel}
/// {@canonicalFor flutterbin_cmd.getFlutterBinVersion}
library;

export 'package:process_run/src/flutterbin_cmd.dart'
    show
        getFlutterBinVersion,
        getFlutterBinChannel,
        isFlutterSupported,
        flutterDartExecutablePath,
        flutterExecutablePath,
        isFlutterSupportedSync;

export 'src/common/dartbin.dart';
