@TestOn('vm')
library process_run.doc_test;

import 'package:test/test.dart';
import 'package:process_run/shell_run.dart';

void main() {
  group('doc', () {
    test('run', () async {
      try {
        await run('firebase --version');
        await run('''
        dart --version
        git status
        ''');
      } catch (_) {}
    });
  });
}
