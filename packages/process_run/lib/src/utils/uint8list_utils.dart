import 'dart:typed_data';

/// Ensure the list is a Uint8List, convert if necessary.
Uint8List asUint8List(List<int> data) {
  if (data is Uint8List) {
    return data;
  }
  return Uint8List.fromList(data);
}
