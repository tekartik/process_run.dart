library process_run.hex_utils;

int _ACodeUnit = 'A'.codeUnitAt(0);
int _aCodeUnit = 'a'.codeUnitAt(0);
int _0CodeUnit = '0'.codeUnitAt(0);

int _hexCharValue(int charCode) {
  if (charCode >= _ACodeUnit && charCode < _ACodeUnit + 6) {
    return charCode - _ACodeUnit + 10;
  }
  if (charCode >= _ACodeUnit && charCode < _aCodeUnit + 6) {
    return charCode - _aCodeUnit + 10;
  }
  if (charCode >= _0CodeUnit && charCode < _0CodeUnit + 10) {
    return charCode - _0CodeUnit;
  }
  return null;
}

int _hexCodeUint4(int value) {
  value = value & 0xF;
  if (value < 10) {
    return _0CodeUnit + value;
  } else {
    return _ACodeUnit + value - 10;
  }
}

int _hex1CodeUint8(int value) {
  return _hexCodeUint4((value & 0xF0) >> 4);
}

int _hex2CodeUint8(int value) {
  return _hexCodeUint4(value);
}

String byteToHex(int value) {
  return new String.fromCharCodes(
      [_hex1CodeUint8(value), _hex2CodeUint8(value)]);
}

String bytesToHex(List<int> bytes) {
  StringBuffer sb = new StringBuffer();
  for (int byte in bytes) {
    sb.write(byteToHex(byte));
  }
  return sb.toString();
}

// It safely ignores non hex data so it can contain spaces or line feed
List<int> hexToBytes(String text) {
  List<int> bytes = new List();
  int firstNibble = null;

  text.codeUnits.forEach((int charCode) {
    if (firstNibble == null) {
      firstNibble = _hexCharValue(charCode);
    } else {
      int secondNibble = _hexCharValue(charCode);
      if (secondNibble != null) {
        bytes.add(firstNibble * 16 + secondNibble);
        firstNibble = null;
      }
    }
  });
  return bytes;
}
