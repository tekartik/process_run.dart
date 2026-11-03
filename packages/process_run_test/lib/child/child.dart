#!/usr/bin/env dart

/// A child process for the process tests: waits, starts its own children (a
/// chain), reports when they are all ready and exits with explicit codes on
/// the signals it catches. Compiled by `compileChild()`, not imported.
///
/// Output (stdout), one line each:
/// * `ready <pid>`: the process and its descendants are started; the lines of
///   its descendants come first, so `ready <rootPid>` comes last.
/// * `signal <SIGNAME>`: a caught signal (before exiting or ignoring it).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:pub_semver/pub_semver.dart';

/// Child version, bump it to force a re-compile by `compileChild()`.
final childVersion = Version(0, 1, 1);

/// Waits (`--wait`, 60 seconds by default), starting first a chain of
/// `--depth` descendants, then exits with `--exit-code`.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Usage help', negatable: false)
    ..addFlag('version', help: 'Print the command version', negatable: false)
    ..addOption(
      'wait',
      help: 'Milliseconds to wait before exiting',
      defaultsTo: '60000',
    )
    ..addOption(
      'depth',
      help:
          'Descendants to start, a chain: 2 starts a child which starts a '
          'grandchild (same options, depth - 1)',
      defaultsTo: '0',
    )
    ..addOption('exit-code', abbr: 'x', help: 'Exit code once waited')
    ..addOption(
      'sigterm-exit-code',
      help: 'Catch sigterm and exit with this code (not on Windows)',
    )
    ..addOption(
      'sigint-exit-code',
      help: 'Catch sigint and exit with this code',
    )
    ..addFlag(
      'ignore-sigterm',
      help: 'Catch sigterm and keep running (not on Windows)',
      negatable: false,
    );
  final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }
  if (options.flag('help')) {
    stdout.writeln('Process run test child');
    stdout.writeln();
    stdout.writeln(parser.usage);
    return;
  }
  if (options.flag('version')) {
    stdout.write(childVersion);
    return;
  }
  int? intOption(String name) => int.tryParse(options.option(name) ?? '');
  var wait = intOption('wait') ?? 60000;
  var depth = intOption('depth') ?? 0;
  var sigtermExitCode = intOption('sigterm-exit-code');
  var sigintExitCode = intOption('sigint-exit-code');
  var ignoreSigterm = options.flag('ignore-sigterm');

  Future<void> exitOnSignal(ProcessSignal signal, int code) async {
    stdout.writeln('signal $signal');
    await stdout.flush();
    exit(code);
  }

  /// Watches [signal], false when it cannot be watched (sigterm on Windows,
  /// where the watch fails later, on the stream).
  bool watch(ProcessSignal signal, void Function() onSignal) {
    if (Platform.isWindows && signal == ProcessSignal.sigterm) {
      return false;
    }
    try {
      signal.watch().listen((_) => onSignal(), onError: (Object _) {});
      return true;
    } catch (_) {
      return false;
    }
  }

  if (ignoreSigterm) {
    watch(
      ProcessSignal.sigterm,
      () => stdout.writeln('signal ${ProcessSignal.sigterm}'),
    );
  } else if (sigtermExitCode != null) {
    watch(
      ProcessSignal.sigterm,
      () => unawaited(exitOnSignal(ProcessSignal.sigterm, sigtermExitCode)),
    );
  }
  if (sigintExitCode != null) {
    watch(
      ProcessSignal.sigint,
      () => unawaited(exitOnSignal(ProcessSignal.sigint, sigintExitCode)),
    );
  }

  if (depth > 0) {
    // The same options, one level less.
    var childArguments = [
      '--wait=$wait',
      '--depth=${depth - 1}',
      if (options.option('exit-code') case var code?) '--exit-code=$code',
      if (sigtermExitCode != null) '--sigterm-exit-code=$sigtermExitCode',
      if (sigintExitCode != null) '--sigint-exit-code=$sigintExitCode',
      if (ignoreSigterm) '--ignore-sigterm',
    ];
    var child = await Process.start(
      Platform.resolvedExecutable,
      childArguments,
    );
    unawaited(child.stderr.pipe(stderr));
    var childReady = Completer<void>();
    child.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        stdout.writeln(line);
        if (line == 'ready ${child.pid}' && !childReady.isCompleted) {
          childReady.complete();
        }
      },
    );
    await Future.any([childReady.future, child.exitCode]);
  }
  stdout.writeln('ready $pid');
  await Future<void>.delayed(Duration(milliseconds: wait));
  exitCode = intOption('exit-code') ?? 0;
}
