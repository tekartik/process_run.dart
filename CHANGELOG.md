# Changelog

## 0.8.0

* Deprecate old commands helper dartCmd, pubCmd... to use constructors instead
  (DartCmd, PubCmd...)

## 0.7.0

* add flutter command support
* add Windows support
* add which utility

## 0.6.0

* dart2 support

## 0.5.6

* supports `implicit-casts: false`

## 0.5.5

* when using io.stdout and io.stderr, flush them when running a command

## 0.5.4

* Fix handling of stdin

## 0.5.2

* fix dart2js to have a libraryRoot argument
* add dartdevc

## 0.5.1

* fix devRun

## 0.5.0

* deprecated connectStdout and connectStrerr in ProcessCmd
* add stdin, stdout, verbose and commandVerbose parameter for run

## 0.4.0

* add stdin and deprecated buggy connectStdin

## 0.3.3

* add argumentToString to handle basic quote or double quote

## 0.3.2

* fix dartdoc to add --packages argument along with the snapshot

## 0.3.0

* Add runCmd (cmd_run library)

## 0.2.0

* Add ProcessCmd

## 0.1.0

* Initial version, run and dartbin utilities
