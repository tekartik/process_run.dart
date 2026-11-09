library;

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/src/platform/platform.dart';

import 'characters.dart';
import 'shell_utils.dart' as shell_utils;

/// windows common executable extensions
const windowsDefaultPathExt = <String>['.exe', '.bat', '.cmd', '.com'];

/// windows env path separator
const String windowsEnvPathSeparator = ';';

/// posix env path separator
const String posixEnvPathSeparator = ':';

/// env path key
const envPathKey = 'PATH';

/// Get the env path separator
String get envPathSeparator =>
    platformIoIsWindows ? windowsEnvPathSeparator : posixEnvPathSeparator;

/// Write a string line to the ouput
void streamSinkWriteln(
  StreamSink<List<int>> sink,
  String message, {
  Encoding? encoding,
}) {
  encoding ??= shellContext.encoding;
  streamSinkWrite(sink, '$message\n', encoding: encoding);
}

/// Write a string to a to sink
void streamSinkWrite(
  StreamSink<List<int>> sink,
  String message, {
  Encoding? encoding,
}) {
  encoding ??= shellContext.encoding;
  sink.add(encoding.encode(message));
}

/// Helper to run a process and connect the input/output for verbosity
///

/// Helper to run a process and connect the input/output for verbosity
///

/// Use to safely enclose an argument if needed
///
/// argument must not be null
String argumentToString(String argument) =>
    argumentToStringImpl(argument, windows: p.context.style == p.Style.windows);

/// [argumentToString] for the Windows ([windows] true) or posix splitter (see
/// `shellSplit`).
///
/// On posix a backslash escapes the next character outside quotes and `\`,
/// `"`, `$`, `` ` `` and a newline inside double quotes; the Windows splitter
/// has no escape.
@visibleForTesting
String argumentToStringImpl(String argument, {required bool windows}) {
  var hasWhitespace = false;
  var hasBackslash = false;
  var singleQuoteCount = 0;
  var doubleQuoteCount = 0;
  if (argument.isEmpty) {
    return '""';
  }
  for (final rune in argument.runes) {
    if ((!hasWhitespace) && (isWhitespace(rune))) {
      hasWhitespace = true;
    } else if (rune == 0x0027) {
      // '
      singleQuoteCount++;
    } else if (rune == 0x0022) {
      // "
      doubleQuoteCount++;
    } else if (rune == 0x005C) {
      // \
      hasBackslash = true;
    }
  }

  /// The content of a double quoted posix argument: the backslashes read
  /// back as an escape doubled.
  String posixDoubleQuoted(String text) {
    if (windows || !hasBackslash) {
      return text;
    }
    var sb = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      var char = text[i];
      if (char == r'\') {
        var next = i + 1 < text.length ? text[i + 1] : null;
        if (next == null ||
            next == r'\' ||
            next == '"' ||
            next == r'$' ||
            next == '`' ||
            next == '\n') {
          sb.write(r'\');
        }
      }
      sb.write(char);
    }
    return sb.toString();
  }

  if (singleQuoteCount > 0) {
    if (doubleQuoteCount > 0) {
      // simply escape all double quotes
      argument = '"${posixDoubleQuoted(argument).replaceAll('"', '\\"')}"';
    } else {
      argument = '"${posixDoubleQuoted(argument)}"';
    }
  } else if (doubleQuoteCount > 0) {
    argument = "'$argument'";
  } else if (hasWhitespace ||
      (hasBackslash && !windows) ||
      // Read back as a comment otherwise
      argument.startsWith('#')) {
    argument = '"${posixDoubleQuoted(argument)}"';
  }
  return argument;
}

/// Convert multiple arguments to string than can be used in a terminal
String argumentsToString(List<String> arguments) {
  final argumentStrings = <String>[];
  for (final argument in arguments) {
    argumentStrings.add(argumentToString(argument));
  }
  return argumentStrings.join(' ');
}

/// Use to safely enclose an argument if needed
String shellArgument(String argument) => argumentToString(argument);

/// Convert multiple arguments to string than can be used in a terminal
String shellArguments(List<String> arguments) => argumentsToString(arguments);

/// Convert a string command to arguments. compat
List<String> stringToArguments(String command) =>
    shellScriptLineToArguments(command);

/// Convert a string command to arguments. only if not a comment
List<String> shellScriptLineToArguments(String command) =>
    shell_utils.shellSplit(command);

/// True if the line is a comment (compat)
bool isLineComment(String line) => shellScriptLineIsComment(line);
// isLineComment
/// True if the line is a comment.
///
/// line must have been trimmed before
bool shellScriptLineIsComment(String line) {
  return line.startsWith('#') ||
      line.startsWith('// ') ||
      line.startsWith('/// ') ||
      (line == '//') ||
      (line == '///');
}

/// True if the line is to be continue.
///
/// line must have been trimmed before
bool isLineToBeContinued(String line) {
  return line.endsWith(' ^') ||
      line.endsWith(r' \') ||
      (line == '^') ||
      (line == '\\');
}

/// Convert a script to multiple commands, compat
List<String?> scriptToCommands(String script) {
  return shellScriptSplitLines(script);
}

/// Convert a script to multiple commands (single line) or comments
///
/// Comments lines start with # or //
List<String> shellScriptSplitLines(String script, {bool? skipComments}) {
  skipComments ??= false;
  var commands = <String>[];
  // non null when previous line ended with ^ or \
  String? currentCommand;
  for (var line in LineSplitter.split(script)) {
    line = line.trim();

    void addAndClearCurrent(String command) {
      commands.add(command);
      currentCommand = null;
    }

    if (line.isNotEmpty) {
      if (shellScriptLineIsComment(line)) {
        if (!skipComments) {
          commands.add(line);
        }
      } else {
        // append to previous
        if (currentCommand != null) {
          line = '$currentCommand $line';
        }
        if (isLineToBeContinued(line)) {
          // remove ending character
          currentCommand = line.substring(0, line.length - 1).trim();
        } else {
          addAndClearCurrent(line);
        }
      }
    } else {
      // terminate current
      if (currentCommand != null) {
        addAndClearCurrent(currentCommand!);
      }
    }
  }
  // The last line ended with ^ or \
  if (currentCommand?.isNotEmpty ?? false) {
    commands.add(currentCommand!);
  }
  return commands;
}
