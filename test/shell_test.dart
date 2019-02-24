@TestOn("vm")
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void main() {
  group('Shell', () {
    test('arguments', () async {
      var shell = Shell(verbose: true);
      var text = 'Hello  world';
      var results = await shell.run('''
# this will print 'Helloworld'
dart example/echo.dart -o Hello  world
dart example/echo.dart -o $text
# this will print 'Hello  world'
dart example/echo.dart -o "Hello  world"
dart example/echo.dart -o 'Hello  world'
dart example/echo.dart -o ${shellArgument(text)}
''');
      expect(results[0].stdout.toString().trim(), 'Helloworld');
      expect(results[1].stdout.toString().trim(), 'Helloworld');
      expect(results[2].stdout.toString().trim(), 'Hello  world');
      expect(results[3].stdout.toString().trim(), 'Hello  world');
      expect(results[4].stdout.toString().trim(), 'Hello  world');
      expect(results.length, 5);
    });

    test('backslash', () async {
      var shell = Shell(verbose: true);
      var weirdText = r'a/\b c/\d';
      var results = await shell.run('''
dart example/echo.dart -o $weirdText
dart example/echo.dart -o ${shellArgument(weirdText)}

''');

      expect(results[0].stdout.toString().trim(), r'a/\bc/\d');
      expect(results[1].stdout.toString().trim(), r'a/\b c/\d');
      expect(results.length, 2);
    });
    test('dart', () async {
      var shell = Shell(verbose: true);
      var results = await shell.run('''dart --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('cd', () async {
      var shell = Shell(verbose: true);

      var results = await shell.run('dart test/src/current_dir.dart');

      expect(results[0].stdout.toString().trim(), Directory.current.path);

      results = await shell.cd('test/src').run('''
dart current_dir.dart
''');
      expect(results[0].stdout.toString().trim(),
          join(Directory.current.path, 'test', 'src'));
    });

    test('pushd', () async {
      var shell = Shell(verbose: true);

      var results = await shell.run('dart test/src/current_dir.dart');
      expect(results[0].stdout.toString().trim(), Directory.current.path);

      shell = shell.pushd('test/src');
      results = await shell.run('dart current_dir.dart');
      expect(results[0].stdout.toString().trim(),
          join(Directory.current.path, 'test', 'src'));

      // pop once
      shell = shell.popd();
      results = await shell.run('dart test/src/current_dir.dart');
      expect(results[0].stdout.toString().trim(), Directory.current.path);

      // pop once
      shell = shell.popd();
      results = await shell.run('dart test/src/current_dir.dart');
      expect(results[0].stdout.toString().trim(), Directory.current.path);
    });
    test('dart_no_path', () async {
      var environment = Map<String, String>.from(shellEnvironment)
        ..remove('PATH');
      var shell = Shell(environment: environment, verbose: true);
      var results = await shell.run('''dart --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('pub_no_path', () async {
      var environment = Map<String, String>.from(shellEnvironment)
        ..remove('PATH');
      var shell = Shell(environment: environment, verbose: true);
      var results = await shell.run('''pub --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('escape backslash', () async {
      var shell = Shell(verbose: true);
      var results = await shell.run('''echo "\\"''');
      expect(results[0].stdout.toString().trim(), '\\');
    });
    test('others', () async {
      try {
        var shell = Shell(verbose: false, runInShell: Platform.isWindows);
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
    }); // skip windows for now
  });

  Future _testCommand(String command) async {
    var shell = Shell();
    try {
      await shell.run(command);
    } on ShellException catch (_) {
      // we only accept shell exception here
    }
  }

  test('various command', () async {
    // that can be installed or not
    await _testCommand('firebase --version'); // firebase.cmd on windows
    await _testCommand('flutter --version'); // flutter.bat on windows
    await _testCommand('dart --version'); // dart.exe on windows
    await _testCommand(
        '${shellArgument(dartExecutable)} --version'); // dart.exe on windows
    await _testCommand('pub --version'); // dart.exe on windows
    // on windows, system command or alias in PowerShell
    await _testCommand('echo Hello world');
  });

  test('echo', () async {
    await _testCommand('echo Hello world'); // alias to Write-Output
    await _testCommand('echo Hello world'); // alias to Write-Output
  });

  test('user', () {
    if (Platform.isWindows) {
      expect(userHomePath, Platform.environment['USERPROFILE']);
      expect(userAppDataPath, Platform.environment['APPDATA']);
    } else {
      expect(userHomePath, Platform.environment['HOME']);
      expect(userAppDataPath, join(Platform.environment['HOME'], '.config'));
    }
  });
}