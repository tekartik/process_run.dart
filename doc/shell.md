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

the command will be looked in the system paths (`PATH` variable). See section later in this this document about
adding system paths.

## Running the script

A script is composed of 1 or multiple lines. Each line becomes a command:
- Each line is trimmed.
- A line starting with `#` will be ignored. `//` and `///` comments are also supported
- A line ending with ` ^` (a space and the `^` character) or ` \\` (a space and one backslash) continue on the next
    line.
- Each command must evaluate to one executable (i.e. no loop, pipe, redirection, bash/powershell specific features).
- Each first word of the line is the executable whose path is resolved using the `which` command. 

If you have spaces in one argument, it must be escaped using double quotes or the `shellArgument` method:

```dart
import 'package:process_run/shell_run.dart';

await run('echo "Hello world"');
await run('echo ${shellArgument('Hello world')}');
```

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

If somehow you cannot modify the system path, it will look for any path (last) defined in
 `~/.config/tekartik/process_run/env.yaml` on Mac/Linux or `%APPDATA%\tekartik\process_run\env.yaml` on Windows.
 
 See [User configuration file](user_config.md) documentation.
 
### Command line

$ pub global active process_run
$ alias ds='pub global run process_run:shell'
 
 