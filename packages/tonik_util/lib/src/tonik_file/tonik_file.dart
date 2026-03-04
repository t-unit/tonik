import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'package:tonik_util/src/tonik_file/file_reader_stub.dart'
    if (dart.library.io) 'package:tonik_util/src/tonik_file/file_reader_io.dart'
    as reader;

/// Transport-agnostic file reference for binary properties.
///
/// Use [TonikFileBytes] for in-memory data or [TonikFilePath] for
/// file-system references. The generator converts these to
/// `MultipartFile.fromBytes` or `MultipartFile.fromFile` at serialization
/// time.
sealed class TonikFile {
  const TonikFile({this.fileName});

  /// Optional filename (including extension) for the multipart part.
  ///
  /// When null, the generator uses the OAS property name as a fallback.
  final String? fileName;

  /// Returns the raw binary content.
  ///
  /// For [TonikFileBytes], returns the in-memory bytes directly.
  /// For [TonikFilePath], reads the file from disk synchronously on
  /// native platforms. Throws [UnsupportedError] on web.
  List<int> toBytes();

  /// URI-encodes this file's binary content.
  ///
  /// Converts the binary data to a UTF-8 string, then URI-encodes it.
  /// Throws a [FormatException] for empty data when [allowEmpty] is false.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) {
    final raw = toBytes();
    if (raw.isEmpty && !allowEmpty) {
      throw const FormatException('Empty binary value');
    }
    if (raw.isEmpty) return '';
    const decoder = Utf8Decoder(allowMalformed: true);
    final str = decoder.convert(raw);
    return useQueryComponent
        ? Uri.encodeQueryComponent(str)
        : Uri.encodeComponent(str);
  }
}

/// In-memory binary data, optionally with a filename.
@immutable
class TonikFileBytes extends TonikFile {
  /// Creates a [TonikFileBytes] with the given [bytes] and optional
  /// [fileName].
  const TonikFileBytes(this.bytes, {super.fileName});

  /// The raw binary content.
  final List<int> bytes;

  @override
  List<int> toBytes() => bytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TonikFileBytes &&
          fileName == other.fileName &&
          const ListEquality<int>().equals(bytes, other.bytes);

  @override
  int get hashCode =>
      Object.hash(fileName, const ListEquality<int>().hash(bytes));

  @override
  String toString() =>
      'TonikFileBytes(${bytes.length} bytes, '
      'fileName: $fileName)';
}

/// A file-system path reference, optionally with a filename override.
///
/// On native platforms, [toBytes] and [toBase64] read the file from disk
/// synchronously. On web, they throw [UnsupportedError] — use
/// [TonikFileBytes] instead.
@immutable
class TonikFilePath extends TonikFile {
  /// Creates a [TonikFilePath] with the given [path] and optional
  /// [fileName].
  const TonikFilePath(this.path, {super.fileName});

  /// Absolute or relative path to the file on disk.
  final String path;

  @override
  List<int> toBytes() => reader.readFileAsBytes(path);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TonikFilePath &&
          fileName == other.fileName &&
          path == other.path;

  @override
  int get hashCode => Object.hash(fileName, path);

  @override
  String toString() => 'TonikFilePath($path, fileName: $fileName)';
}
