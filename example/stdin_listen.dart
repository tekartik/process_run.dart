#!/usr/bin/env dart
library process_command.echo_param;

import 'dart:io';

main(List<String> arguments) async {
  stdin.listen((List<int> data) {
    print(data.toString());
  });
  /*
  stdin.listen((List<int> data) {    print(data.toString());
  });
  */
}
