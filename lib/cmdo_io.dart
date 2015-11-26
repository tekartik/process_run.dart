library tekartik_cmdo.cmdo_io;

import 'package:cmdo/src/cmdo/cmdo_base.dart';
import 'cmdo.dart';
export 'cmdo.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

part 'src/cmdo/cmdo_io_impl.dart';

// The global executor
IoCommandExecutor io = new IoCommandExecutor();

abstract class IoCommandExecutor extends Object
    with CommandExecutorMixin
    implements CommandExecutor {
  factory IoCommandExecutor() => new _IoCommandExecutorImpl();

  // for use of Process.start
  Future<CommandResult> runInputAsync(CommandInput input);
  IoCommandExecutor._();
}
