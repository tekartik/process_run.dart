library tekartik_cmdo.test.cmdo_test_common;

export 'package:dev_test/test.dart';
import 'package:cmdo/cmdo.dart';
export 'package:cmdo/cmdo.dart';
import 'package:cmdo/cmdo_dry.dart';
export 'dart:async';
import 'dart:async';

const String testExecutableThrows = "com.tekartik.cmdo.test.dummy.throws";
CommandInput testCommandThrows =
    commandInput(testExecutableThrows, null, throwException: true);

class TestDryCommandExecutor extends DryCommandExecutor {
  Future<CommandResult> runInput(CommandInput input) async {
    CommandResult result = await super.runInput(input);

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
