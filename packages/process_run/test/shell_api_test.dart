import 'package:process_run/shell.dart';
import 'package:process_run/src/env_utils.dart' show kDartIsWeb;
import 'package:test/test.dart';

void main() {
  group('shell_api_test', () {
    test('public', () {
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
