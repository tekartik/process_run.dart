import 'dart:async';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/stdio.dart';
import 'package:process_run/which.dart';

Future main() async {
  stdout.writeln('flutter: ${await which('flutter')}');
  var flutterBinVersion = await getFlutterBinVersion();
  stdout.writeln('flutterBinVersion: $flutterBinVersion');
}
