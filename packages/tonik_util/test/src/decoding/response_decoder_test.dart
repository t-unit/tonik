import 'dart:convert';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('Response decoders', () {
    group('JSON content type', () {
      test('decodes JSON object', () {
        final bytes = utf8.encode('{"key": "value", "number": 42}');
        final result = decodeResponseJson<Map<String, Object?>>(bytes);

        expect(result, isA<Map<String, Object?>>());
        expect(result['key'], 'value');
        expect(result['number'], 42);
      });

      test('decodes JSON array', () {
        final bytes = utf8.encode('[1, 2, 3, 4, 5]');
        final result = decodeResponseJson<List<Object?>>(bytes);

        expect(result, isA<List<Object?>>());
        expect(result, [1, 2, 3, 4, 5]);
      });

      test('decodes JSON string primitive', () {
        final bytes = utf8.encode('"hello world"');
        final result = decodeResponseJson<String>(bytes);

        expect(result, 'hello world');
      });

      test('decodes JSON number primitive', () {
        final bytes = utf8.encode('42');
        final result = decodeResponseJson<int>(bytes);

        expect(result, 42);
      });

      test('decodes JSON boolean primitive', () {
        final bytes = utf8.encode('true');
        final result = decodeResponseJson<bool>(bytes);

        expect(result, isTrue);
      });

      test('decodes JSON null', () {
        final bytes = utf8.encode('null');
        final result = decodeResponseJson<Object?>(bytes);

        expect(result, isNull);
      });

      test('handles empty JSON object', () {
        final bytes = utf8.encode('{}');
        final result = decodeResponseJson<Map<String, Object?>>(bytes);

        expect(result, isA<Map<String, Object?>>());
        expect(result.isEmpty, isTrue);
      });

      test('handles nested JSON structures', () {
        const json =
            '{"user": {"name": "John", "age": 30}, "tags": ["a", "b"]}';
        final bytes = utf8.encode(json);
        final result = decodeResponseJson<Map<String, Object?>>(bytes);

        expect(result, isA<Map<String, Object?>>());
        expect(result['user'], isA<Map<String, Object?>>());
        expect((result['user']! as Map<String, Object?>)['name'], 'John');
        expect(result['tags'], isA<List<Object?>>());
      });
    });

    group('text content type', () {
      test('decodes plain text string', () {
        final bytes = utf8.encode('Hello, World!');
        final result = decodeResponseText(bytes);

        expect(result, isA<String>());
        expect(result, 'Hello, World!');
      });

      test('decodes empty string', () {
        final bytes = utf8.encode('');
        final result = decodeResponseText(bytes);

        expect(result, isA<String>());
        expect(result, '');
      });

      test('decodes multiline text', () {
        const text = 'Line 1\nLine 2\nLine 3';
        final bytes = utf8.encode(text);
        final result = decodeResponseText(bytes);

        expect(result, isA<String>());
        expect(result, text);
      });

      test('decodes text with special characters', () {
        const text = 'Special chars: à é î ö ü 中文 🎉';
        final bytes = utf8.encode(text);
        final result = decodeResponseText(bytes);

        expect(result, isA<String>());
        expect(result, text);
      });

      test('handles large text', () {
        final text = 'x' * 10000;
        final bytes = utf8.encode(text);
        final result = decodeResponseText(bytes);

        expect(result, isA<String>());
        expect(result.length, 10000);
      });
    });

    group('type validation', () {
      test('throws ResponseDecodingException when JSON type mismatch', () {
        final bytes = utf8.encode('{"key": "value"}');

        expect(
          () => decodeResponseJson<List<Object?>>(bytes),
          throwsA(isA<ResponseDecodingException>()),
        );
      });
    });
  });
}
