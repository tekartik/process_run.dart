#!/usr/bin/env dart
library tekartik_command.test.command_example.dart;

import 'dart:io';

main(List<String> arguments) {
  // first arg is stdout
  if (arguments.length > 0) {
    stdout.writeln(arguments[0]);
  }
  // second is stderr
  if (arguments.length > 1) {
    stderr.writeln(arguments[1]);
  }
  // third is exitCode
  if (arguments.length > 2) {
    exit(int.parse(arguments[2]));
  }
}
