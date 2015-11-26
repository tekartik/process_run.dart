library tekartik_command.command_io;

import 'package:command/src/command/command_base.dart';
import 'command.dart';
export 'command.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

part 'src/command/command_io_impl.dart';

// The global executor
IoCommandExecutor io = new IoCommandExecutor();

abstract class IoCommandExecutor extends Object
    with CommandExecutorMixin
    implements CommandExecutor {
  factory IoCommandExecutor() => new _IoCommandExecutorImpl();

  // for use of Process.start
  Future<CommandResult> runCmdAsync(CommandInput input);
  IoCommandExecutor._();
}
