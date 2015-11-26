# cmdo.dart

Command line helpers for Linux/Win/Mac

[![Build Status](https://travis-ci.org/tekartik/cmdo.dart.svg?branch=master)](https://travis-ci.org/tekartik/cmdo.dart)

## Usage

Calling a system command

````
import 'package:cmdo/cmdo_io.dart';
...
await io.run('echo', ['hello world']);
````

Calling dart

````
import 'package:cmdo/dartbin.dart';
...
await io.runCmd(dartCmd(['--version']));
````
