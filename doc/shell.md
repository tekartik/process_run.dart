### Shell

Allows to run script from Mac/Windows/Linux in a portable way

```dart
final shell = Shell();
await shell.run('''

# This is a comment
echo Hello world
firebase --version

''');
```

More information [on shell here](https://github.com/tekartik/process_run/blob/master/doc/shell.md)

## Exception

### echo

that is actually the command that requires a shell on windows, this is supported for convenience