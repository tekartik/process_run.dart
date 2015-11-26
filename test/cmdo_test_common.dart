library tekartik_cmdo.test.cmdo_test;

export 'package:dev_test/test.dart';
import 'package:cmdo/cmdo_dry.dart' as _dry;
import 'package:cmdo/cmdo.dart';
export 'package:cmdo/cmdo.dart';
import 'dart:async';
export 'dart:async';

const String testExecutableThrows = "com.tekartik.cmdo.test.dummy.throws";
CommandInput testCommandThrows =
    new CommandInput(executable: testExecutableThrows, throwException: true);

class TestDryCommandExecutor extends _dry.CommandExecutor {
  Future<CommandResult> run(CommandInput input) async {
    CommandResult result = await super.run(input);

    // Only throw if asked for
    if (input.throwException == true) {
      if (input.executable == testExecutableThrows) {
        throw "TestDry throw from ${result}";
      }
    }
    return result;
  }
}

_dry.CommandExecutor dry = new TestDryCommandExecutor();
