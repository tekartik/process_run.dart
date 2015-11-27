# process_run.dart

Process run for Linux/Win/Mac

[![Build Status](https://travis-ci.org/tekartik/process_run.dart.svg?branch=master)](https://travis-ci.org/tekartik/process_run.dart)

## Usage

Calling a system command

````
import 'package:process_run/process_run.dart';
...
await run('echo', ['hello world']);
````

Calling dart

````
import 'package:process_run/dartbin.dart';
...
await run(dartExecutable, ['--version']);
````
