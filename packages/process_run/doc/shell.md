# Shell

Allows to run script from Mac/Windows/Linux in a portable way. Empty lines are added for readibility

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

## Running the script in synchronous mode

`runSync` and `runExecutableArgumentsSync` are available since 0.14.1 in the global space and in the `Shell` class.
They are synchronous version of `run` and `runExecutableArguments` respectively with some limitations.

The synchronous mode is useful for testing. It is not recommended for production use as
it is a synchronous call and will block until the child process terminates.

```dart     
var shell = Shell();
// This is a synchronous call and will block until the child process terminates.
var results = shell.runSync('echo "Hello world"');
var result = results.first;
print('output: "${result.outText.trim()}" exitCode: ${result.exitCode}');
// should display: output: "Hello world" exitCode: 0
```

**Warning**:
- You cannot feed any stdin to the child process.
- You cannot kill a synchronous child process.
- Available since 0.14.1
- Recommended for testing only, it is a synchronous call and will block until the child process terminates.

### Handling errors

By default, `run` will throw an error if the `exitCode` is not 0. You can prevent that
with the option `throwOnError` which is true by default:

```dart
void main(List<String> arguments) async {
  // Prevent error to be thrown if exitCode is not 0
  var shell = Shell(throwOnError: false);
  // This won't throw
  await shell.run('dir dummy_folder');

  shell = Shell();
  // This throws an error!
  await shell.run('dir dummy_folder');
}
```

### Adding system path

If somehow you cannot modify the system path, it will look for any path (last) defined in
 `~/.config/tekartik/process_run/env.yaml` on Mac/Linux or `%APPDATA%\tekartik\process_run\env.yaml` on Windows.
 
 See [User configuration file](user_config.md) documentation.
 
### Command line

```shell
# ds on the PATH (Dart 3.10+), or `dart pub global activate process_run` (legacy)
$ dart install process_run
# from a project depending on process_run
$ dart run process_run:ds --version
```
 
### Helper

`ShellLinesController` gives the output of a command as lines, or feeds its
input; use one per direction. Prefer it (with `Shell`) to `dart:io`
`Process.start`, tests included.

Output, as lines:

```dart
var controller = ShellLinesController();
var shell = Shell(stdout: controller.sink, verbose: false);
controller.stream.listen((event) {
  // Handle output

  // ...
  // If needed kill the shell
  shell.kill();
});
try {
  await shell.run('dart echo.dart some_text');
} on ShellException catch (_) {
  // We might get a shell exception
}
```

Input, written while the command runs (for example once it printed a
prompt); closing the controller is the end of input of the command:

```dart
var input = ShellLinesController();
var shell = Shell(stdin: input.binaryStream, verbose: false);
var done = shell.run('sort');
input.writeln('b');
input.writeln('a');
// End of input: sort then writes its output and exits
input.close();
print((await done).outLines); // (a, b)
```

Both together drive an interactive program: wait for a line on the output
controller, answer on the input one. The process-run-shell skill
(`skills/process-run-shell/SKILL.md`) has the full example, with a timeout
killing a program that hangs.

### Shared stdin

`sharedStdIn` is the program's own stdin, which several commands
(`Shell(stdin: sharedStdIn)`) and prompts (`prompt`, `promptConfirm`) can
read in turn. Call `await sharedStdIn.terminate()` before the program ends,
otherwise it never exits.

At the end of its input (stdin a pipe, `< /dev/null`, CI), its listeners get
done: `sharedStdIn.lines()` completes, a command given `stdin: sharedStdIn`
gets its end of input, and `prompt`, `promptConfirm` and
`sharedStdIn.nextLine()` throw a `StateError` (no element).

### Running sudo (Linux)

You can run your dart program using sudo to run all you child scripts as a super user.

Running a shell script with sudo from inside a dart script ran in non super user mode 
is a little bit trickier as it requires user interaction. One solution (tried on Ubuntu) is to use
`sudo --stdin` to specify reading the password from the stdin.

You can then run script using the following:

```dart
await shell.run('sudo --stdin lsof -i:22');
```

A shared stdin object could be used to redirect dart program input to shell objects.

Here is a more complex example:
```dart
import 'package:process_run/shell.dart';

/// Only works on linux, list the process listening on port 22
void main(List<String> arguments) async {
  /// We have use a shared stdin if we want to reuse it.
  var stdin = sharedStdIn;

  /// Use sudo --stdin to read the password from stdin
  /// Use an alias for simplicity (only need to refer to sudo instead of sudo --stdin
  var env = ShellEnvironment()..aliases['sudo'] = 'sudo --stdin';
  var shell = Shell(
      stdin: sharedStdIn,
      // lsof return exitCode 1 if not found
      environment: env,
      throwOnError: false);

  await shell.run('sudo lsof -i:22');
  // second time should not ask for password
  await shell.run('sudo lsof -i:80');

  /// Stop shared stdin
  await stdin.terminate();
}
```

If you have the password in a variable and not access to stdin (for example in some flutter scenario), you
can do something like:

```dart
import 'dart:io';

import 'package:http/http.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

void main(List<String> arguments) async {
  // Assuming you have the password in `pwd` variable

  // Use sudo --stdin to read the password from stdin
  // Use an alias for simplicity (only need to refer to sudo instead of sudo --stdin
  var env = ShellEnvironment()..aliases['sudo'] = 'sudo --stdin';

  // Create a fake stdin stream from the password variable
  var stdin =
      ByteStream.fromBytes(systemEncoding.encode(pwd)).asBroadcastStream();

  // Execute!
  var shell = Shell(stdin: stdin, environment: env);

  // Should not ask for password
  await shell.run('sudo lsof -i:22');
  await shell.run('sudo lsof -i:80');
}
```

### Running sudo (MacOS)

Turn off Sandboxing by removing it from the Signing & Capabilities tab:

![alt text](https://i.stack.imgur.com/iTRFC.png)

Then run your commands via `osascript` like so:

```
  await shell.run('''
     osascript -e 'do shell script "[YOUR_SHELL_COMMAND_GOES_HERE]" with administrator privileges'
  ''')
```

That will prompt for the user to type his password and then will run the script.

### Killing a shell

You can kill a shell using the `kill()` method. Without a signal (since 1.4.2), it kills the running command and all
its descendants (children, grandchildren...): `ProcessSignal.sigterm` first, so that they can clean up (git removes its
lock file), then `ProcessSignal.sigkill` for the ones still running after 5 seconds. On Windows the whole tree is
terminated at once (taskkill).

You can specify a signal using the `signal` parameter, it is then sent to the running command only (as `kill()` did
before 1.4.2), such as `ProcessSignal.sigint` (ctrl-c) to stop the Firebase emulators.

A special trick is made when `ProcessSignal.sigkill` used as it will force killing all the descendant processes (children, grandchildren...)
on Windows (taskkill), MacOS and Linux (since 1.4.2, `pkill -P` before, direct children only).
As I was experiencing with `dhttpd`, killing the process was not really killing the server so using `sigkill` was properly
killing the server.

### Killing processes

`ShellProcesses` finds and kills any process by its pid, not only the ones a shell started (Linux, MacOS and Windows),
the way `ps`, `pgrep` and `kill` do in a terminal:

```dart
// The running processes of an executable, an app started from elsewhere.
var pids = await ShellProcesses.findByExecutable('deploy/linux/my_app');
// sigterm, then sigkill for the ones still running after 5 seconds, their
// descendants (children, grandchildren...) too.
var stillRunning = await ShellProcesses.kill(pids, tree: true);

// The descendants of a process, its state.
var descendants = await ShellProcesses.descendantsOf(process.pid);
var running = await ShellProcesses.isRunning(process.pid);
```

The processes of another user are seen (`isRunning`, `descendantsOf`) but usually not found by their executable
(except on MacOS) and cannot be killed (unless root or administrator).
