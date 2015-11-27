# command.dart

Command line helpers for Linux/Win/Mac

[![Build Status](https://travis-ci.org/tekartik/cmdo.dart.svg?branch=master)](https://travis-ci.org/tekartik/command.dart)

## Usage

Calling a system command

````
import 'package:command/command.dart';
...
await run('echo', ['hello world']);
````

Calling dart

````
import 'package:cmdo/dartbin.dart';
...
await runCmd(dartCmd(['--version']));
````
