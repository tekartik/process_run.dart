@TestOn('vm')
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

@deprecated
bool devTrue = true;
// bool debug = devTrue;
bool debug = false;

void main() {
  group('Shell', () {
    test('public', () {
      // ignore: unnecessary_statements
      getFlutterBinVersion;
      // ignore: unnecessary_statements
      getFlutterBinChannel;
      isFlutterSupported;
      isFlutterSupportedSync;
      dartVersion;
      dartChannel;
      // ignore: unnecessary_statements
      dartChannelStable;
      // ignore: unnecessary_statements
      dartChannelBeta;
      // ignore: unnecessary_statements
      dartChannelDev;
      // ignore: unnecessary_statements
      dartChannelMaster;

      // ignore: unnecessary_statements
      promptConfirm;
      // ignore: unnecessary_statements
      prompt;
      // ignore: unnecessary_statements
      promptTerminate;
    });
    test('arguments', () async {
      var shell = Shell(verbose: debug);
      var text = 'Hello  world';
      var results = await shell.run('''
# this will print 'Helloworld'
dart example/echo.dart -o Hello  world
dart example/echo.dart -o $text
# this will print 'Hello  world'
dart example/echo.dart -o 'Hello  world'
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
      var shell = Shell(verbose: debug);
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
      var shell = Shell(verbose: debug);
      var results = await shell.run('''dart --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('dart runExecutableArguments', () async {
      var shell = Shell(verbose: debug);
      var result = await shell.runExecutableArguments('dart', ['--version']);
      expect(result.exitCode, 0);
    });
    test('dart runExecutableArguments bad arg', () async {
      var shell = Shell(verbose: debug);
      try {
        await shell.runExecutableArguments('dart', ['--bad-arg']);
        fail('shoud fail');
      } on ShellException catch (e) {
        expect(e.result.exitCode, 255);
      }
    });

    test('cd', () async {
      var shell = Shell(verbose: debug);

      var results = await shell.run('dart test/src/current_dir.dart');

      expect(results[0].stdout.toString().trim(), Directory.current.path);

      results = await shell.cd('test/src').run('''
dart current_dir.dart
''');
      expect(results[0].stdout.toString().trim(),
          join(Directory.current.path, 'test', 'src'));
    });

    test('path', () {
      var shell = Shell();
      expect(shell.path, isNotEmpty);
      shell = shell.pushd('test');
      expect(basename(shell.path), 'test');
    });
    test('pushd', () async {
      var shell = Shell(verbose: debug);

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
      expect(shell.popd(), isNull);
    });
    test('dart_no_path', () async {
      var environment = Map<String, String>.from(shellEnvironment)
        ..remove('PATH');
      var shell = Shell(environment: environment, verbose: debug);
      var results = await shell.run('''dart --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('pub_no_path', () async {
      print(userPaths);
      var environment = Map<String, String>.from(shellEnvironment)
        ..remove('PATH');
      var shell = Shell(environment: environment, verbose: false);
      var results = await shell.run('''pub --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('escape backslash', () async {
      var shell = Shell(verbose: debug);
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
    var shell = Shell(verbose: debug);
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

  test('pipe', () async {
    var dir = join('.dart_tool', 'process_run', 'test');
    await Directory(dir).create(recursive: true);
    var file = File(join(dir, 'echo.output'));
    var shell = Shell();

    // Write to file
    await file.writeAsString(
        (await shell.run('echo Hello world')).first.stdout.toString());

    // Append to file
    await file.writeAsString(
        (await shell.run('echo Hello world')).first.stdout.toString(),
        mode: FileMode.append);

    var separator = Platform.isWindows ? '\r\n' : '\n';
    expect(await file.readAsString(),
        'Hello world${separator}Hello world$separator');
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

  test('userLoadEnvFile', () async {
    //print(a);
    var path = join('test', 'data', 'test_env1.yaml');
    userLoadEnvFile(path);
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
    path = join('test', 'data', 'test_env_dummy_file.yaml');
    userLoadEnvFile(path);
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
  });

  test('userLoadEnv', () async {
    userLoadEnv(vars: {'test': '1'}, paths: ['my_path']);
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
    userLoadEnv();
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
  });

  test('ShellException bad command', () async {
    var shell = Shell();
    try {
      await shell.run('dummy_command_that_does_not_exist');
    } on ShellException catch (e) {
      expect(e.message.contains('workingDirectory'), isTrue);
    }
  });
  test('ShellException bad directory', () async {
    var shell = Shell(workingDirectory: 'dummy_directory_that_does_not_exist');
    try {
      await shell.run('dart --version');
    } on ShellException catch (e) {
      expect(e.message.contains('workingDirectory'), isTrue);
    }
  });
  test('User path', () async {
    // TODO test on other platform
    if (Platform.isLinux) {
      var environment = {
        'PATH': '${absolute('test/src')}:${platformEnvironment['PATH']}'
      };
      print(environment);
      var shell =
          Shell(environment: environment, includeParentEnvironment: false);
      await shell.run('current_dir');
    }
  });
  test('flutter_resolve', () async {
    // Edge case finding flutter from dart
    if (Platform.isLinux) {
      var paths = platformEnvironment['PATH'].split(':')
        ..removeWhere((element) => element.endsWith('flutter/bin'));

      paths.insert(0, dartSdkBinDirPath);
      print(paths);
      var environment = {'PATH': '${paths.join(':')}'};
      print(environment);
      var shell =
          Shell(environment: environment, includeParentEnvironment: false);
      await shell.run('flutter --version');
    }
  }, skip: !isFlutterSupportedSync);

  test('flutter info', () async {
    expect(await getFlutterBinVersion(), isNotNull);
    expect(await getFlutterBinChannel(), isNotNull);
  }, skip: !isFlutterSupportedSync);
}
