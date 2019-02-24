import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell/src/shell_utils.dart';
import 'package:test/test.dart';

void main() {
  test('scriptToCommands', () {
    expect(scriptToCommands(''), []);
    expect(scriptToCommands(' e\n#\n # comment\nf \n '), ['e', 'f']);
  });

  test('user', () {
    expect(userHomePath, Platform.environment['HOME']);
    if (Platform.isWindows) {
      expect(userAppDataPath, Platform.environment['APPDATA']);
    } else {
      expect(userAppDataPath, join(Platform.environment['HOME'], '.config'));
    }
  });
}
