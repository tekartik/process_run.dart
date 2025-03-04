/// {@canonicalFor prompt.prompt}
/// {@canonicalFor prompt.promptConfirm}
/// {@canonicalFor prompt.promptTerminate}
/// {@canonicalFor process_run.src.shell_utils_common.shellArgument}
/// {@canonicalFor user_config.userLoadEnv}
/// {@canonicalFor user_config.userLoadEnvFile}
/// {@canonicalFor shell_utils.platformEnvironment}
/// {@canonicalFor shell_utils.shellEnvironment}
/// {@canonicalFor shell_utils.userAppDataPath}
/// {@canonicalFor user_config.userEnvironment}
/// {@canonicalFor shell_utils.userHomePath}
/// {@canonicalFor user_config.userPaths}
/// {@canonicalFor process_run.runExecutableArguments}
library;

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
        shellArgument,
        shellEnvironment,
        platformEnvironment,
        shellArguments,
        shellExecutableArguments;
export 'package:process_run/src/shell_utils_common.dart'
    show argumentsToString, argumentToString, stringToArguments;
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
export 'src/lines_utils.dart' show ShellLinesController, shellStreamLines;
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
export 'src/shell.dart'
    show run, runSync, Shell, ShellException, ShellOnProcessCallback;
export 'src/shell_environment.dart'
    show
        ShellEnvironment,
        ShellEnvironmentPaths,
        ShellEnvironmentVars,
        ShellEnvironmentAliases;
export 'src/shell_environment_common.dart' show ShellEnvironmentCommonExt;
export 'src/which.dart' show whichSync, which;
export 'utils/process_result_extension.dart'
    show
        ProcessRunProcessExt,
        ProcessRunProcessResultExt,
        ProcessRunProcessResultsExt;
