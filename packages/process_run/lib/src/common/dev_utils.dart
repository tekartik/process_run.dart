/// Development helpers to generate warning in code
library;

import 'package:meta/meta.dart';

void _devPrint(Object object) {
  if (_devPrintEnabled) {
    // ignore: avoid_print
    print(object);
  }
}

bool _devPrintEnabled = true;

@Deprecated('Dev only')
set devPrintEnabled(bool enabled) => _devPrintEnabled = enabled;

/// Print only in dev mode
@Deprecated('Dev only')
void devPrint(Object? object) {
  if (_devPrintEnabled) {
    // ignore: avoid_print
    print(object);
  }
}

@Deprecated('Dev only')

/// Warning in dev mode
T devWarning<T>(T t) => t;

void _devError([Object? msg]) {
  // one day remove the print however sometimes the error thrown is hidden
  try {
    throw UnsupportedError('$msg');
  } catch (e, st) {
    if (_devPrintEnabled) {
      // ignore: avoid_print
      print('# ERROR $msg');
      // ignore: avoid_print
      print(st);
    }
    rethrow;
  }
}

@Deprecated('Dev only')

/// Error in dev mode
void devError([String? msg]) => _devError(msg);

/// exported for testing
@visibleForTesting
void debugDevPrint(Object object) => _devPrint(object);

/// exported for testing
@visibleForTesting
void debugDevError(Object object) => _devError(object);

set debugDevPrintEnabled(bool enabled) => _devPrintEnabled = enabled;
