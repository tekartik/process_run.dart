import '../process_run.dart';

/// Shell command run options
class ShellCommandRunOptions {
  /// Run options
  ShellCommandRunOptions({this.onProcess});

  /// On process callback
  final ShellOnProcessCallback? onProcess;

  /// Copy with
  ShellCommandRunOptions copyWith({ShellOnProcessCallback? onProcess}) {
    return ShellCommandRunOptions(onProcess: onProcess ?? this.onProcess);
  }
}
