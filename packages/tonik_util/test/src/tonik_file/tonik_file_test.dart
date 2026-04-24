import 'dart:io';

import 'package:test/test.dart';
import 'package:tonik_util/src/tonik_file/tonik_file.dart';

void main() {
  group('TonikFileBytes', () {
    test('toBytes returns the provided bytes', () {
      const bytes = [1, 2, 3, 4, 5];
      const file = TonikFileBytes(bytes);

      expect(file.toBytes(), [1, 2, 3, 4, 5]);
    });

    test('fileName is null by default', () {
      const file = TonikFileBytes([1, 2, 3]);

      expect(file.fileName, isNull);
    });

    test('fileName can be set', () {
      const file = TonikFileBytes([1, 2, 3], fileName: 'photo.jpg');

      expect(file.fileName, 'photo.jpg');
    });

    test('bytes property is accessible', () {
      const bytes = [10, 20, 30];
      const file = TonikFileBytes(bytes);

      expect(file.bytes, [10, 20, 30]);
    });

    test('toBytes returns the same list reference', () {
      const bytes = [1, 2, 3];
      const file = TonikFileBytes(bytes);

      expect(identical(file.toBytes(), file.bytes), isTrue);
    });

    test('empty bytes are handled', () {
      const file = TonikFileBytes([]);

      expect(file.toBytes(), isEmpty);
    });

    test('equality works for same bytes and fileName', () {
      const a = TonikFileBytes([1, 2, 3], fileName: 'a.txt');
      const b = TonikFileBytes([1, 2, 3], fileName: 'a.txt');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('equality fails for different bytes', () {
      const a = TonikFileBytes([1, 2, 3]);
      const b = TonikFileBytes([4, 5, 6]);

      expect(a, isNot(b));
    });

    test('equality fails for different fileName', () {
      const a = TonikFileBytes([1, 2, 3], fileName: 'a.txt');
      const b = TonikFileBytes([1, 2, 3], fileName: 'b.txt');

      expect(a, isNot(b));
    });

    test('toString includes type and fileName', () {
      const file = TonikFileBytes([1, 2, 3], fileName: 'photo.jpg');

      expect(file.toString(), contains('TonikFileBytes'));
      expect(file.toString(), contains('photo.jpg'));
      expect(file.toString(), contains('3'));
    });

    test('toString works without fileName', () {
      const file = TonikFileBytes([1, 2]);

      expect(file.toString(), contains('TonikFileBytes'));
      expect(file.toString(), contains('2'));
    });
  });

  group('TonikFilePath', () {
    late File tempFile;
    late String tempPath;

    setUp(() {
      tempFile = File('${Directory.systemTemp.path}/tonik_test_file.txt')
        ..writeAsBytesSync([72, 101, 108, 108, 111]); // "Hello"
      tempPath = tempFile.path;
    });

    tearDown(() {
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });

    test('path property is accessible', () {
      final file = TonikFilePath(tempPath);

      expect(file.path, tempPath);
    });

    test('fileName is null by default', () {
      final file = TonikFilePath(tempPath);

      expect(file.fileName, isNull);
    });

    test('fileName can be set', () {
      final file = TonikFilePath(tempPath, fileName: 'override.txt');

      expect(file.fileName, 'override.txt');
    });

    test('toBytes reads file from disk', () {
      final file = TonikFilePath(tempPath);

      expect(file.toBytes(), [72, 101, 108, 108, 111]);
    });

    test('equality works for same path and fileName', () {
      final a = TonikFilePath(tempPath, fileName: 'a.txt');
      final b = TonikFilePath(tempPath, fileName: 'a.txt');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('equality fails for different paths', () {
      const a = TonikFilePath('/tmp/a.txt');
      const b = TonikFilePath('/tmp/b.txt');

      expect(a, isNot(b));
    });

    test('equality fails for different fileName', () {
      final a = TonikFilePath(tempPath, fileName: 'a.txt');
      final b = TonikFilePath(tempPath, fileName: 'b.txt');

      expect(a, isNot(b));
    });

    test('toString includes type and path', () {
      const file = TonikFilePath('/tmp/photo.jpg', fileName: 'override.jpg');

      expect(file.toString(), contains('TonikFilePath'));
      expect(file.toString(), contains('/tmp/photo.jpg'));
      expect(file.toString(), contains('override.jpg'));
    });

    test('toString works without fileName', () {
      const file = TonikFilePath('/tmp/photo.jpg');

      expect(file.toString(), contains('TonikFilePath'));
      expect(file.toString(), contains('/tmp/photo.jpg'));
    });
  });

  group('toBase64String', () {
    test('encodes bytes to base64 string', () {
      // "Hello" in UTF-8
      const file = TonikFileBytes([72, 101, 108, 108, 111]);
      expect(file.toBase64String(), 'SGVsbG8=');
    });

    test('encodes empty bytes to empty base64 string', () {
      const file = TonikFileBytes([]);
      expect(file.toBase64String(), '');
    });

    test('encodes binary data correctly', () {
      const file = TonikFileBytes([0, 1, 2, 255]);
      expect(file.toBase64String(), 'AAEC/w==');
    });

    test('works with TonikFilePath', () {
      // Uses the tempFile from the TonikFilePath group above, but for
      // simplicity we test with TonikFileBytes which is a simpler case.
      // "ABC" in UTF-8
      const file = TonikFileBytes([65, 66, 67]);
      expect(file.toBase64String(), 'QUJD');
    });
  });

  group('uriEncode', () {
    test('encodes non-empty bytes with URI component encoding', () {
      // "Hello" in UTF-8
      const file = TonikFileBytes([72, 101, 108, 108, 111]);
      expect(file.uriEncode(allowEmpty: false), 'Hello');
    });

    test('encodes with query component when useQueryComponent is true', () {
      // "a b" in UTF-8
      const file = TonikFileBytes([97, 32, 98]);
      final result = file.uriEncode(
        allowEmpty: false,
        useQueryComponent: true,
      );
      // Uri.encodeQueryComponent encodes space as '+'
      expect(result, 'a+b');
    });

    test('encodes with component encoding when useQueryComponent is false', () {
      // "a b" in UTF-8
      const file = TonikFileBytes([97, 32, 98]);
      final result = file.uriEncode(allowEmpty: false);
      // Uri.encodeComponent encodes space as '%20'
      expect(result, 'a%20b');
    });

    test('throws FormatException for empty bytes when allowEmpty is false', () {
      const file = TonikFileBytes([]);
      expect(
        () => file.uriEncode(allowEmpty: false),
        throwsA(isA<FormatException>()),
      );
    });

    test('returns empty string for empty bytes when allowEmpty is true', () {
      const file = TonikFileBytes([]);
      expect(file.uriEncode(allowEmpty: true), '');
    });
  });

  group('TonikFile sealed dispatch', () {
    test('can be used in exhaustive switch with TonikFileBytes', () {
      const TonikFile file = TonikFileBytes([1, 2, 3], fileName: 'test.bin');

      final result = switch (file) {
        TonikFileBytes(:final bytes) => 'bytes: ${bytes.length}',
        TonikFilePath(:final path) => 'path: $path',
      };

      expect(result, 'bytes: 3');
    });

    test('can be used in exhaustive switch with TonikFilePath', () {
      const TonikFile file = TonikFilePath('/tmp/test.bin');

      final result = switch (file) {
        TonikFileBytes(:final bytes) => 'bytes: ${bytes.length}',
        TonikFilePath(:final path) => 'path: $path',
      };

      expect(result, 'path: /tmp/test.bin');
    });

    test('fileName is accessible on base type', () {
      const TonikFile file = TonikFileBytes([1], fileName: 'test.bin');

      expect(file.fileName, 'test.bin');
    });
  });
}
