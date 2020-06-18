# process_run

Process run helpers for Linux/Win/Mac.

[![Build Status](https://travis-ci.org/tekartik/process_run.dart.svg?branch=master)](https://travis-ci.org/tekartik/process_run.dart)

## Goals

Currently using `Process.run` does not stream output which is not convenient for lengthy
operation. It requires using `Process.start` in a more complex way.

`run` and `runCmd` add verbose helper for that. Also dart binaries (pub, dart2js...) and any
script can be called consistently on Mac/Windows/Linux

`ProcessCmd` allow creating command object that can be run and modified.

## Usage

### run

Additional options to `Process.run` are
* specifying stdin
* making it verbose

Additional feature
* It tries to resolve simple command like `dart`, `firebase`, `flutter`, or any script available on the user path
  on any Platform.

```dart
import 'package:process_run/process_run.dart';
```

Display dart version and the command executed:

```dart
await run('dart', ['--version'], verbose: true);
```


### which

Like unix `which`, it searches for installed executables

```dart
import 'package:process_run/which.dart';
```

Find `flutter` and `firebase` executables:

```dart
var flutterExectutable = whichSync('flutter');
var firebaseExectutable = whichSync('firebase');

```

### shell


Allows to run script from Mac/Windows/Linux in a portable way. Empty lines are added for lisibility

```dart
import 'package:process_run/shell.dart';
```

Run a simple script:

```dart
var shell = Shell();

await shell.run('''

# Display some text
echo Hello

# Display dart version
dart --version

# Display pub version
pub --version

''');
```

More information [on shell here](https://github.com/tekartik/process_run.dart/blob/master/doc/shell.md)

### Flutter context

#### MacOS

If you want to run executable in a MacOS flutter context, you need to disable sandbox mode. See 
[Removing sandboxing](https://stackoverflow.com/questions/7018354/remove-sandboxing) and 
[ProcessException: Operation not permitted on macOS](https://github.com/tekartik/process_run.dart/issues/3) 

### Additional features

Addtional features and information are [available here](https://github.com/tekartik/process_run.dart/blob/master/doc/more.md)

