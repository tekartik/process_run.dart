#!/usr/bin/env dart
library process_command.echo_param;

import 'dart:io';

main(List<String> arguments) async {
  for (String argument in arguments) {
    stdout.writeln(argument);
  }
}
