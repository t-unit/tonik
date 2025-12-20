import 'dart:convert';

/// Extension methods for encoding binary data (`List<int>`) to String for JSON.
extension BinaryToStringEncoder on List<int> {
  /// Decodes this binary data (`List<int>`) to a String using UTF-8 decoding.
  ///
  /// Uses Utf8Decoder with allowMalformed: true to handle any byte sequence.
  /// This is used when serializing binary data to JSON, where it must be
  /// represented as a string.
  String decodeToString() {
    const decoder = Utf8Decoder(allowMalformed: true);
    return decoder.convert(this);
  }
}
