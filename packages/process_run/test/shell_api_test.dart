// ignore_for_file: dead_code

import 'dart:io' as io;

import 'package:process_run/shell.dart';
import 'package:process_run/src/env_utils.dart' show kDartIsWeb;
import 'package:test/test.dart';

void main() {
  group('shell_api_test', () {
    test('public', () {
      io.Process;
      var processResult = io.ProcessResult(0, 0, '', '');
      expect(processResult.exitCode, 0);
      // ignore_for_file: unnecessary_statements
      if (!kDartIsWeb) {
        sharedStdIn;
        dartVersion;
        dartChannel;
        dartExecutable;

        userHomePath;
        userAppDataPath;
        shellEnvironment;
        platformEnvironment;
        userPaths;
        userEnvironment;
        isFlutterSupportedSync;
        isFlutterSupported;
      }
      shellArgument;
      shellArguments;
      shellExecutableArguments;
      userLoadEnvFile;
      userLoadEnv;
      getFlutterBinVersion;
      getFlutterBinChannel;
      ShellLinesController;
      shellStreamLines;
      promptConfirm;
      promptTerminate;
      prompt;
      run;
      runSync;
      runExecutableArguments;
      runExecutableArgumentsSync;
      Shell;
      ShellOptions;
      ShellException;
      ShellEnvironment;
      ShellEnvironmentPaths;
      ShellEnvironmentVars;
      ShellEnvironmentAliases;
      ShellOnProcessCallback;
      whichSync;
      which;
      ProcessRunProcessResultsExt(null)?.outText;
      ProcessRunProcessResultExt(null)?.outText;
      ProcessRunProcessExt(null)?.outLines;
      // process_cmd
      ProcessCmd;
      processResultToDebugString;
      processCmdToDebugString;
      // shell_utils
      stringToArguments;
    });
  });
}
