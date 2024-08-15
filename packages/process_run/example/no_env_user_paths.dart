import 'dart:async';

import 'package:process_run/src/user_config.dart';
import 'package:process_run/stdio.dart';

Future main() async {
  var userPaths = getUserPaths(<String, String>{});
  for (var path in userPaths) {
    stdout.writeln(path);
  }
}
