import 'dart:io';

String getShellCmdBinFileName(String command) =>
    '$command${Platform.isWindows ? '.bat' : ''}';
