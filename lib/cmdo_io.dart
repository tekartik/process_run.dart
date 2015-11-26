library tekartik_cmdo.cmdo_io;

import 'cmdo.dart' as cmdo;
import 'cmdo.dart' show CommandInput, CommandResult, CommandOutput;
export 'cmdo.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

// set to true for quick debugging
bool debugCmdoIo = false;

class CommandExecutor implements cmdo.CommandExecutor {
  Future<CommandResult> run(CommandInput input) async {
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
    if (input.connectIo == true) {
      // print('# start);
      Process process = await Process.start(input.executable, input.arguments,
          workingDirectory: input.workingDirectory,
          environment: input.environment,
          runInShell: input.runInShell);
      StringBuffer out = new StringBuffer();
      StringBuffer err = new StringBuffer();

      output = new CommandOutput();
      await Future.wait([
        process.stdout.listen((d) {
          stdout.add(d);
          out.write(UTF8.decode(d));
        }).asFuture(),
        process.stderr.listen((d) {
          stderr.add(d);
          err.write(UTF8.decode(d));
        }).asFuture(),
        process.exitCode.then((int exitCode) {
          output.exitCode = exitCode;
        })
      ]);
      output.out = const LineSplitter().convert(out.toString().trim());
      output.err = const LineSplitter().convert(err.toString().trim());
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

      if (err != null) {
        if (input.throwException == true) {
          return new Future.error(err);
        }
      }
      if (result != null) {
        output = new CommandOutput();

        String out = result.stdout;
        output.out = const LineSplitter().convert(out.toString().trim());
        String err = result.stderr;
        output.err = const LineSplitter().convert(err.toString().trim());
        output.exitCode = result.exitCode;
      }
    }

    if (debugCmdoIo) {
      print('$output');
    }

    return getResult();
  }
}
