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

/*
/// dart2js
/// [libraryRoot] necessary and computed if not provided
List<String> dart2jsArguments({List<String> args, String libraryRoot}) {
  args ??= [];
  List<String> dart2jsArgs = new List.from(args);
  if (libraryRoot == null) {
    libraryRoot = dartSdkDirPath;
  }
  dart2jsArgs.insertAll(0, ['--library-root=${libraryRoot}']);
  return dart2jsArgs;
}

/// dartdoc
List<String> dartdocArguments({List<String> args, String packages}) {

  packages ??=
      join(dartSdkBinDirPath, 'snapshots', 'resources', cmd, '.packages');
  return new List<String>.from(args)
    ..insertAll(0, ['--packages=${packages}', dartbinCmdSnapshot(cmd)]);
}
*/
