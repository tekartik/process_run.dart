import 'dart:io';

import 'package:path/path.dart';

String _dartExecutable;

///
/// Get dart vm either from executable or using the which command
///
String get dartExecutable => _dartExecutable ??= Platform.resolvedExecutable;

String get dartSdkBinDirPath => dirname(dartExecutable);

String get dartSdkDirPath => dirname(dartSdkBinDirPath);
