# Shell

Allows to run script from Mac/Windows/Linux in a portable way. Empty lines are added for lisibility

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

the command will be looked in the system paths (`PATH` variable).

### Changing directory

You can pushd/popd a directory

```dart
shell = shell.pushd('example');

await shell.run('''

# Listing directory in the example folder
dir

''');
shell = shell.popd();
```


### Adding system path

If somehow you cannot modify the system path, it will look for any path defined in
 `~/.config/tekartik/process_run/env.yaml` on Mac/Linux or `%APPDATA%\tekartik\process_run\env.yaml` on Windows.