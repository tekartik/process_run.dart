@TestOn("vm")
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell/shell.dart';
import 'package:test/test.dart';

void main() {
  group('Shell', () {
    test('dart', () async {
      var shell = Shell(verbose: false);
      var results = await shell.run('''dart --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);

      results = await shell.run('''
dart example/echo.dart -o Hello world
dart example/echo.dart -o ${shellArgument('Hello world')}
dart example/echo.dart -e hi
''');
      expect(results.length, 3);
      expect(results[0].stdout.toString().trim(), 'Helloworld');
      expect(results[1].stdout.toString().trim(), 'Hello world');
      expect(results[2].stderr.toString().trim(), 'hi');
    });

    test('others', () async {
      try {
        var shell = Shell(verbose: false);
        await shell.run('''
echo Hello world
firebase --version
adb --version
_tekartik_dummy_app_that_does_not_exits
''');
        fail('should fail');
      } on Exception catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
    }, skip: Platform.isWindows); // skip windows for now
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
