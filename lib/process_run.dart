///
/// Helper to run a process and connect the input/output for verbosity
///
library process_run;

import 'dart:io';
import 'dart:io' as io;
import 'dart:convert';
import 'dart:async';

///
/// Returns `true` if [rune] represents a whitespace character.
///
/// The definition of whitespace matches that used in [String.trim] which is
/// based on Unicode 6.2. This maybe be a different set of characters than the
/// environment's [RegExp] definition for whitespace, which is given by the
/// ECMAScript standard: http://ecma-international.org/ecma-262/5.1/#sec-15.10
///
/// from quiver
///
bool _isWhitespace(int rune) => ((rune >= 0x0009 && rune <= 0x000D) ||
    rune == 0x0020 ||
    rune == 0x0085 ||
    rune == 0x00A0 ||
    rune == 0x1680 ||
    rune == 0x180E ||
    (rune >= 0x2000 && rune <= 0x200A) ||
    rune == 0x2028 ||
    rune == 0x2029 ||
    rune == 0x202F ||
    rune == 0x205F ||
    rune == 0x3000 ||
    rune == 0xFEFF);

// argument must not be null
String argumentToString(String argument) {
  bool hasWhitespace = false;
  int singleQuoteCount = 0;
  int doubleQuoteCount = 0;
  if (argument.length == 0) {
    return '""';
  }
  for (int rune in argument.runes) {
    if ((!hasWhitespace) && (_isWhitespace(rune))) {
      hasWhitespace = true;
    } else if (rune == 0x0027) { // '
      singleQuoteCount++;
    } else if (rune == 0x0022) { // "
      doubleQuoteCount++;
    }
  }
  if (singleQuoteCount > 0) {
    if (doubleQuoteCount > 0) {
      // simply escape all double quotes
      argument = '"${argument.replaceAll('"', '\\"')}"';
    } else {
      argument = '"$argument"';
    }
  } else if (doubleQuoteCount > 0) {
    argument = "'$argument'";
  } else if (hasWhitespace) {
    argument = '"$argument"';
  }
  return argument;
}

String argumentsToString(List<String> arguments) {
  List<String> argumentStrings = [];
  for (String argument in arguments) {

    argumentStrings.add(argumentToString(argument));
  }
  return argumentStrings.join(' ');
}

String executableArgumentsToString(String executable, List<String> arguments) {
  StringBuffer sb = new StringBuffer();
  sb.write(executable);
  if (arguments is List && arguments.isNotEmpty) {
    sb.write(" ${argumentsToString(arguments)}");
  }
  return sb.toString();
}

Future<ProcessResult> run(String executable, List<String> arguments,
    {String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    Encoding stdoutEncoding: SYSTEM_ENCODING,
    Encoding stderrEncoding: SYSTEM_ENCODING,
    bool connectStdout: false,
    bool connectStderr: false,
    Stream<List<int>> stdin,
    @deprecated
    bool connectStdin: false}) async {
  Process process = await Process.start(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell);

  StreamController<List<int>> outCtlr = new StreamController();
  StreamController<List<int>> errCtlr = new StreamController();

  // Connected stdin
  // Buggy!
  if (stdin != null) {
    stdin.pipe(process.stdin); //.addStream(stdin);
  // ignore: deprecated_member_use
  } else if (connectStdin) {
    process.stdin.addStream(io.stdin);
  } else {
    // Close the input sync, we want this not interractive
    process.stdin.close();
  }


  Future<dynamic> streamToResult(Stream<List<int>> stream, Encoding encoding) {
    if (encoding == null) {
      List<int> list = [];
      return stream.listen((List<int> data) {
        list.addAll(data);
      }).asFuture(list);
    } else {
      return encoding.decodeStream(stream);
    }
  }

  var out = streamToResult(outCtlr.stream, stdoutEncoding);
  var err = streamToResult(errCtlr.stream, stderrEncoding);

  process.stdout.listen((List<int> d) {
    if (connectStdout) {
      stdout.add(d);
    }
    outCtlr.add(d);
  }, onDone: () {
    outCtlr.close();
  });

  process.stderr.listen((List<int> d) {
    if (connectStderr) {
      stderr.add(d);
    }
    errCtlr.add(d);
  }, onDone: () {
    errCtlr.close();
  });

  int exitCode = await process.exitCode;

  ProcessResult result = new ProcessResult(process.pid, exitCode, await out, await err);

  if (stdin != null) {
    //process.stdin.close();
  }

  return result;
}
