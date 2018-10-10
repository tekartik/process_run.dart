import 'dart:io';

import 'package:path/path.dart';

String _dartExecutable;

///
/// Get dart vm either from executable or using the which command
///
String get dartExecutable {
  if (_dartExecutable == null) {
    _dartExecutable = Platform.resolvedExecutable;
  }
  return _dartExecutable;
}

String get dartSdkBinDirPath => dirname(dartExecutable);

String get dartSdkDirPath => dirname(dartSdkBinDirPath);
