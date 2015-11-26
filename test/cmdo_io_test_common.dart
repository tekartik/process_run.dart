library tekartik_cmdo.test.cmdo_io_test_common;

import 'dart:io';
import 'package:cmdo/cmdo_io.dart' as _io;

export 'cmdo_test_common.dart';

bool debugCmdoIoTestCommon = false;

_io.CommandExecutor io = new _io.CommandExecutor();

///
/// Get dart vm either from executable or using the which command
///
String _dartVmBin;

String get dartVmBin {
  if (_dartVmBin == null) {
    _dartVmBin = Platform.resolvedExecutable;

    if (debugCmdoIoTestCommon) {
      print('dartVmBin: ${_dartVmBin}');
    }
    /*
    if (FileSystemEntity.isLinkSync(_dartVmBin)) {
      String link = _dartVmBin;
      _dartVmBin = new Link(_dartVmBin).targetSync();

      // on mac, if installed with brew, we might get something like ../Cellar/dart/1.12.1/bin
      // so make sure to make it absolute
      if (!isAbsolute(_dartVmBin)) {
        _dartVmBin = absolute(normalize(join(dirname(link), _dartVmBin)));
      }
    }
    */
  }
  return _dartVmBin;
}
