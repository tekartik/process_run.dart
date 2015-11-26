part of tekartik_cmdo.cmdo_io;

// set to true for quick debugging
bool debugCmdoIo = false;

class _IoCommandExecutorImpl extends IoCommandExecutor {
  _IoCommandExecutorImpl() : super._();

  Future<CommandResult> runCmdAsync(CommandInput input) => _runCmd(input, true);

  Future<CommandResult> runCmd(CommandInput input) => _runCmd(input);
  Future<CommandResult> _runCmd(CommandInput input, [bool useStart]) async {
    CommandOutput output;
    CommandResult getResult() {
      return new CommandResult(input, output);
    }

    if (debugCmdoIo) {
      print(input);
    }

    // Invalid argument(s): Arguments is not a List: null
    if (input.arguments == null) {
      input.arguments = [];
    }
    if (useStart == true || input.connectIo == true) {
      // print('# start);
      bool pipe = input.connectIo == true;
      var exception;
      Process process = await Process
          .start(input.executable, input.arguments,
              workingDirectory: input.workingDirectory,
              environment: input.environment,
              runInShell: input.runInShell == true)
          .catchError((e) {
        exception = e;
      });
      // Assume text for now
      StringBuffer out = new StringBuffer();
      StringBuffer err = new StringBuffer();

      output = new CommandOutput();

      if (exception != null) {
        if (input.throwException == true) {
          return new Future.error(err);
        }
        output.exception = err;
      } else {
        await Future.wait([
          process.stdout.listen((d) {
            if (pipe) {
              stdout.add(d);
            }
            out.write(UTF8.decode(d));
          }).asFuture(),
          process.stderr.listen((d) {
            if (pipe) {
              stderr.add(d);
            }
            err.write(UTF8.decode(d));
          }).asFuture(),
          process.exitCode.then((int exitCode) {
            output.exitCode = exitCode;
          })
        ]);
        output.out = out.toString();
        output.err = err.toString();
      }
    } else {
      // print('# run');
      var err;
      ProcessResult result = await Process
          .run(input.executable, input.arguments,
              workingDirectory: input.workingDirectory,
              environment: input.environment,
              runInShell: input.runInShell == true)
          .catchError((e) {
        err = e;
      });

      output = new CommandOutput();
      if (err != null) {
        if (input.throwException == true) {
          return new Future.error(err);
        }
        output.exception = err;
      } else if (result != null) {
        // Assuming text
        String out = result.stdout;
        output.out = out;
        String err = result.stderr;
        output.err = err;
        output.exitCode = result.exitCode;
      }
    }

    if (debugCmdoIo) {
      print('$output');
    }

    return getResult();
  }
}
