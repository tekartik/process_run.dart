// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: comment_references

import 'package:process_run/src/common/ascii_charcodes.dart';
import 'package:string_scanner/string_scanner.dart';

/// Splits [command] into tokens according to [the POSIX shell
/// specification][spec].
///
/// [spec]: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html
///
/// This returns the unquoted values of quoted tokens. For example,
/// `shellSplit('foo "bar baz"')` returns `["foo", "bar baz"]`. It does not
/// currently support here-documents. It does *not* treat dynamic features such
/// as parameter expansion specially. For example, `shellSplit("foo $(bar
/// baz)")` returns `["foo", "$(bar", "baz)"]`.
///
/// This will discard any comments at the end of [command].
///
/// Throws a [FormatException] if [command] isn't a valid shell command.
List<String> shellSplitImpl(String command) {
  final scanner = StringScanner(command);
  final results = <String>[];
  final token = StringBuffer();

  // Whether a token is being parsed, as opposed to a separator character. This
  // is different than just [token.isEmpty], because empty quoted tokens can
  // exist.
  var hasToken = false;

  while (!scanner.isDone) {
    final next = scanner.readChar();
    switch (next) {
      case charcodeBackslash:
        // Section 2.2.1: A <backslash> that is not quoted shall preserve the
        // literal value of the following character, with the exception of a
        // <newline>. If a <newline> follows the <backslash>, the shell shall
        // interpret this as line continuation. The <backslash> and <newline>
        // shall be removed before splitting the input into tokens. Since the
        // escaped <newline> is removed entirely from the input and is not
        // replaced by any white space, it cannot serve as a token separator.
        if (scanner.scanChar(charcodeLf)) break;

        hasToken = true;
        token.writeCharCode(scanner.readChar());
        break;

      case charcodeSingleQuote:
        hasToken = true;
        // Section 2.2.2: Enclosing characters in single-quotes ( '' ) shall
        // preserve the literal value of each character within the
        // single-quotes. A single-quote cannot occur within single-quotes.
        final firstQuote = scanner.position - 1;
        while (!scanner.scanChar(charcodeSingleQuote)) {
          _checkUnmatchedQuote(scanner, firstQuote);
          token.writeCharCode(scanner.readChar());
        }
        break;

      case charcodeDoubleQuote:
        hasToken = true;
        // Section 2.2.3: Enclosing characters in double-quotes ( "" ) shall
        // preserve the literal value of all characters within the
        // double-quotes, with the exception of the characters backquote,
        // <dollar-sign>, and <backslash>.
        //
        // (Note that this code doesn't preserve special behavior of backquote
        // or dollar sign within double quotes, since those are dynamic
        // features.)
        final firstQuote = scanner.position - 1;
        while (!scanner.scanChar(charcodeDoubleQuote)) {
          _checkUnmatchedQuote(scanner, firstQuote);

          if (scanner.scanChar(charcodeBackslash)) {
            _checkUnmatchedQuote(scanner, firstQuote);

            // The <backslash> shall retain its special meaning as an escape
            // character (see Escape Character (Backslash)) only when followed
            // by one of the following characters when considered special:
            //
            //     $ ` " \ <newline>
            final next = scanner.readChar();
            if (next == charcodeLf) continue;
            if (next == charcodeDollar ||
                next == charcodeBackquote ||
                next == charcodeDoubleQuote ||
                next == charcodeBackslash) {
              token.writeCharCode(next);
            } else {
              token
                ..writeCharCode(charcodeBackslash)
                ..writeCharCode(next);
            }
          } else {
            token.writeCharCode(scanner.readChar());
          }
        }
        break;

      case charcodeHash:
        // Section 2.3: If the current character is a '#' [and the previous
        // characters was not part of a word], it and all subsequent characters
        // up to, but excluding, the next <newline> shall be discarded as a
        // comment. The <newline> that ends the line is not considered part of
        // the comment.
        if (hasToken) {
          token.writeCharCode(charcodeHash);
          break;
        }

        while (!scanner.isDone && scanner.peekChar() != charcodeLf) {
          scanner.readChar();
        }
        break;

      case charcodeSpace:
      case charcodeTab:
      case charcodeLf:
        // ignore: invariant_booleans
        if (hasToken) results.add(token.toString());
        hasToken = false;
        token.clear();
        break;

      default:
        hasToken = true;
        token.writeCharCode(next);
        break;
    }
  }

  if (hasToken) results.add(token.toString());
  return results;
}

/// Splits [command] into tokens according to [the POSIX shell
/// specification][spec] slightly modified for windows.
///
/// [spec]: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html
///
/// This returns the unquoted values of quoted tokens. For example,
/// `shellSplit('foo "bar baz"')` returns `["foo", "bar baz"]`. It does not
/// currently support here-documents. It does *not* treat dynamic features such
/// as parameter expansion specially. For example, `shellSplit("foo $(bar
/// baz)")` returns `["foo", "$(bar", "baz)"]`.
///
/// This will discard any comments at the end of [command].
///
/// Throws a [FormatException] if [command] isn't a valid shell command.
List<String> shellSplitWindowsImpl(String command) {
  final scanner = StringScanner(command);
  final results = <String>[];
  final token = StringBuffer();

  // Whether a token is being parsed, as opposed to a separator character. This
  // is different than just [token.isEmpty], because empty quoted tokens can
  // exist.
  var hasToken = false;

  while (!scanner.isDone) {
    final next = scanner.readChar();
    switch (next) {
      case charcodeBackslash:
        // We don't escape backslashes in Windows paths.
        hasToken = true;
        token.writeCharCode(next);
        break;

      case charcodeSingleQuote:
        hasToken = true;
        // Section 2.2.2: Enclosing characters in single-quotes ( '' ) shall
        // preserve the literal value of each character within the
        // single-quotes. A single-quote cannot occur within single-quotes.
        final firstQuote = scanner.position - 1;
        while (!scanner.scanChar(charcodeSingleQuote)) {
          _checkUnmatchedQuote(scanner, firstQuote);
          token.writeCharCode(scanner.readChar());
        }
        break;

      case charcodeDoubleQuote:
        hasToken = true;
        // Section 2.2.3: Enclosing characters in double-quotes ( "" ) shall
        // preserve the literal value of all characters within the
        // double-quotes, with the exception of the characters backquote,
        // <dollar-sign>, and <backslash>.
        //
        // (Note that this code doesn't preserve special behavior of backquote
        // or dollar sign within double quotes, since those are dynamic
        // features.)
        final firstQuote = scanner.position - 1;
        while (!scanner.scanChar(charcodeDoubleQuote)) {
          _checkUnmatchedQuote(scanner, firstQuote);

          // We don't escape backslashes in Windows paths.

          token.writeCharCode(scanner.readChar());
        }
        break;

      case charcodeHash:
        // Section 2.3: If the current character is a '#' [and the previous
        // characters was not part of a word], it and all subsequent characters
        // up to, but excluding, the next <newline> shall be discarded as a
        // comment. The <newline> that ends the line is not considered part of
        // the comment.
        if (hasToken) {
          token.writeCharCode(charcodeHash);
          break;
        }

        while (!scanner.isDone && scanner.peekChar() != charcodeLf) {
          scanner.readChar();
        }
        break;

      case charcodeSpace:
      case charcodeTab:
      case charcodeLf:
        // ignore: invariant_booleans
        if (hasToken) results.add(token.toString());
        hasToken = false;
        token.clear();
        break;

      default:
        hasToken = true;
        token.writeCharCode(next);
        break;
    }
  }

  if (hasToken) results.add(token.toString());
  return results;
}

/// Throws a [FormatException] if [scanner] is done indicating that a closing
/// quote matching the one at position [openingQuote] is missing.
void _checkUnmatchedQuote(StringScanner scanner, int openingQuote) {
  if (!scanner.isDone) return;
  final type = scanner.substring(openingQuote, openingQuote + 1) == '"'
      ? 'double'
      : 'single';
  scanner.error('Unmatched $type quote.', position: openingQuote, length: 1);
}
