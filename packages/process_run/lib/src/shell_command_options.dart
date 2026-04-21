import '../process_run.dart';

/// Shell command run options
class ShellCommandRunOptions {
  /// On process callback
  final ShellOnProcessCallback? onProcess;

  /// Run options
  ShellCommandRunOptions({this.onProcess});

  /// Copy with
  ShellCommandRunOptions copyWith({ShellOnProcessCallback? onProcess}) {
    return ShellCommandRunOptions(onProcess: onProcess ?? this.onProcess);
  }
}
