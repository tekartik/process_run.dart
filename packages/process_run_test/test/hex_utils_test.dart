import 'package:process_run_test/echo/hex_utils.dart';
import 'package:test/test.dart';

void main() {
  group('hex_utils', () {
    test('hexToBytes', () {
      expect(hexToBytes('01 83 3d 79'), [0x01, 0x83, 0x3d, 0x79]);
      expect(hexToBytes('ABCDEF abcdef'), [0xAB, 0xCD, 0xEF, 0xAB, 0xCD, 0xEF]);
      for (var i = 0; i < 256; i++) {
        expect(hexToBytes(byteToHex(i)), [i]);
        expect(hexToBytes(byteToHex(i).toLowerCase()), [i]);
      }
    });
    test('hexToBytes ignores non hex characters', () {
      // G..Z and [\]^_` are not hex digits either.
      expect(hexToBytes('48_65'), [0x48, 0x65]);
      expect(hexToBytes('0G1'), [0x01]);
      expect(hexToBytes('xyz[]^`4Z1'), [0x41]);
    });
  });
}
