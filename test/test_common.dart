library command.test.test_common;

export 'package:dev_test/test.dart';
import 'package:command/command_common.dart';
export 'package:command/command_common.dart';
import 'package:command/command_dry.dart';
export 'dart:async';
import 'dart:async';

const String testExecutableThrows = "com.tekartik.command.test.dummy.throws";
CommandInput testCommandThrows =
    command(testExecutableThrows, null, throwException: true);

class TestDryCommandExecutor extends DryCommandExecutor {
  @override
  Future<CommandResult> runCmd(CommandInput input) async {
    CommandResult result = await super.runCmd(input);

    // Only throw if asked for
    if (input.executable == testExecutableThrows) {
      var exception = new StateError("TestDry throw from ${result}");
      if (input.throwException == true) {
        throw exception;
      } else {
        result.output.exception = exception;
      }
    }

    return result;
  }
}

TestDryCommandExecutor dry = new TestDryCommandExecutor();
