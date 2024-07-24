@TestOn('vm')
library;

import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void main() {
  group('shell_options', () {
    test('clone', () async {
      var env = ShellEnvironment()..aliases['clone_alias'] = 'clone';
      var shellOptions = ShellOptions(environment: env);

      expect(shellOptions.environment.aliases['clone_alias'], 'clone');
      shellOptions = shellOptions.clone();
      expect(shellOptions.environment.aliases['clone_alias'], 'clone');
    });
  });
}
