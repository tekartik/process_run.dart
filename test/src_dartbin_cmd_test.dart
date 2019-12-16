import 'package:process_run/src/dartbin_cmd.dart' show parsePlatformVersion;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('src_dartbin_cmd', () {
    test('parse', () {
      expect(parsePlatformVersion('1.0.0'), Version(1, 0, 0));
      expect(
          parsePlatformVersion('2.7.0 (Unknown timestamp)'), Version(2, 7, 0));
    });
  });
}
