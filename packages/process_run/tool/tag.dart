import 'dart:io';

import 'package:process_run/package/package.dart';
import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();
  var version = await getPackageVersion();
  stdout.writeln('Version $version');
  stdout.writeln('Tap anything or CTRL-C: $version');

  await stdin.first;
  await shell.run('''
git tag v$version
git push origin --tags
''');
}
