/// @docImport 'package:process_run/src/shell_utils.dart';
/// @docImport 'package:process_run/src/shell_utils_common.dart';
/// {@canonicalFor prompt.prompt}
/// {@canonicalFor prompt.promptConfirm}
/// {@canonicalFor prompt.promptTerminate}
/// {@canonicalFor shell_utils_common.shellArgument}
/// {@canonicalFor user_config.userLoadEnv}
/// {@canonicalFor user_config.userLoadEnvFile}
/// {@canonicalFor process_run.runExecutableArguments}
library;

export 'dart:io' show ProcessResult;

export 'package:process_run/dartbin.dart'
    show
        dartVersion,
        dartChannel,
        dartExecutable,
        dartChannelStable,
        dartChannelBeta,
        dartChannelDev,
        dartChannelMaster;
export 'package:process_run/src/api/shell_common.dart' show ShellOptions;
// We reuse io sharedStdIn definition.
export 'package:process_run/src/io/shared_stdin.dart' show sharedStdIn;
export 'package:process_run/src/shell_utils.dart'
    show
        userHomePath,
        userAppDataPath,
        shellEnvironment,
        platformEnvironment,
        shellArguments,
        shellExecutableArguments;
export 'package:process_run/src/shell_utils_common.dart'
    show
        shellScriptSplitLines,
        shellScriptLineIsComment,
        shellScriptLineToArguments,
        argumentsToString,
        argumentToString,
        stringToArguments,
        shellArgument;
export 'package:process_run/src/user_config.dart'
    show userPaths, userEnvironment, userLoadEnvFile, userLoadEnv;

export 'dartbin.dart'
    show
        getFlutterBinVersion,
        getFlutterBinChannel,
        isFlutterSupported,
        isFlutterSupportedSync,
        flutterDartExecutablePath,
        flutterExecutablePath;
export 'src/lines_utils_common.dart'
    show ShellLinesController, shellStreamLines;
export 'src/process_cmd.dart'
    show
        processCmdToDebugString,
        processResultToDebugString,
        /// Deprecated
        ProcessCmd;
export 'src/process_run.dart'
    show
        runExecutableArguments,
        executableArgumentsToString,
        runExecutableArgumentsSync;
export 'src/prompt.dart' show promptConfirm, promptTerminate, prompt;
export 'src/shell.dart' show run, runSync, Shell, ShellOnProcessCallback;
export 'src/shell_command.dart' show ShellCommand, ProcessRunShellCommandExt;
export 'src/shell_command_options.dart' show ShellCommandRunOptions;
export 'src/shell_environment.dart'
    show
        ShellEnvironment,
        ShellEnvironmentPaths,
        ShellEnvironmentVars,
        ShellEnvironmentAliases;
export 'src/shell_environment_common.dart' show ShellEnvironmentCommonExt;
export 'src/shell_exception.dart' show ShellException;
export 'src/shell_process_result.dart'
    show
        ShellProcessResults,
        ShellProcessResult,
        ProcessRunShellProcessResultExt,
        ProcessRunShellProcessResultsExt;
export 'src/which.dart' show whichSync, which;
export 'utils/process_result_extension.dart'
    show
        ProcessRunProcessExt,
        ProcessRunProcessResultExt,
        ProcessRunProcessResultsExt,
        ProcessRunFutureProcessResultsExt;
