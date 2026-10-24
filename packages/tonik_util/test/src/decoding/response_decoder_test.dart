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

      test('decodes JSON using the supplied charset', () {
        final result = decodeResponseJson<String>(const [
          0x22,
          0x63,
          0x61,
          0x66,
          0xe9,
          0x22,
        ], contentType: 'application/problem+json; charset=latin1');

        expect(result, 'café');
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

    group('form content type', () {
      test('normalizes percent-encoded Latin-1 form values', () {
        final result = decodeResponseForm(
          ascii.encode('name=caf%E9'),
          contentType: 'application/x-www-form-urlencoded; charset=latin1',
        );

        expect(result, 'name=caf%C3%A9');
      });

      test(
        'preserves encoded syntax, list commas, duplicate keys and order',
        () {
          final result = decodeResponseForm(
            ascii.encode('caf%E9=%26%3D%2B%2C+x&items=caf%E9,a%2Cb&caf%E9=fin'),
            contentType: 'application/x-www-form-urlencoded; charset=latin1',
          );

          expect(
            result,
            'caf%C3%A9=%26%3D%2B%2C+x&items=caf%C3%A9,a%2Cb&caf%C3%A9=fin',
          );
          final listValue = result.split('&')[1].split('=')[1];
          expect(listValue.decodeFormStringList(), ['café', 'a,b']);
        },
      );

      test('decodes multibyte fields with escaped and literal trail bytes', () {
        final result = decodeResponseForm(
          ascii.encode('mark=%81K'),
          contentType: 'application/x-www-form-urlencoded; charset=shift-jis',
        );

        expect(result, 'mark=%E3%82%9C');
      });

      test('preserves encoded spaces in form property names', () {
        final result = decodeResponseForm(
          ascii.encode('first%20name=caf%E9'),
          contentType: 'application/x-www-form-urlencoded; charset=latin1',
        );
        final fields = result.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'first name'},
          listKeys: {},
        );

        expect(result, 'first%20name=caf%C3%A9');
        expect(fields['first name'].decodeFormString(), 'café');
      });

      test('normalizes UTF-16BE encoded keys and values', () {
        final result = decodeResponseForm(
          ascii.encode('%00n%00a%00m%00e=%00c%00a%00f%00%E9'),
          contentType: 'application/x-www-form-urlencoded; charset=utf-16be',
        );

        expect(result, 'name=caf%C3%A9');
      });

      test('continues accepting raw Latin-1 text in form values', () {
        final result = decodeResponseForm(const [
          0x6e,
          0x61,
          0x6d,
          0x65,
          0x3d,
          0x63,
          0x61,
          0x66,
          0xe9,
        ], contentType: 'application/x-www-form-urlencoded; charset=latin1');

        expect(result, 'name=caf%C3%A9');
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

      test('uses UTF-8 when Content-Type has no charset', () {
        final bytes = utf8.encode('Grüße 👋');

        expect(
          decodeResponseText(bytes, contentType: 'text/plain'),
          'Grüße 👋',
        );
      });

      test('parses quoted charset case-insensitively', () {
        final bytes = utf8.encode('Grüße 👋');

        expect(
          decodeResponseText(bytes, contentType: 'Text/Plain; Charset="UTF-8"'),
          'Grüße 👋',
        );
      });

      test('accepts the common utf8 alias', () {
        final bytes = utf8.encode('Grüße 👋');

        expect(
          decodeResponseText(bytes, contentType: 'text/plain; charset=utf8'),
          'Grüße 👋',
        );
      });

      test('decodes ISO-8859-1', () {
        const bytes = [0x63, 0x61, 0x66, 0xe9];

        expect(
          decodeResponseText(
            bytes,
            contentType: 'text/plain; charset=iso-8859-1',
          ),
          'café',
        );
      });

      test('decodes Windows-1252 distinctly from ISO-8859-1', () {
        const bytes = [0x93, 0x54, 0x6f, 0x6e, 0x69, 0x6b, 0x94, 0x20, 0x80];

        expect(
          decodeResponseText(
            bytes,
            contentType: 'text/plain; charset=windows-1252',
          ),
          '“Tonik” €',
        );
      });

      test('decodes Windows-1251', () {
        const bytes = [0xcf, 0xf0, 0xe8, 0xe2, 0xe5, 0xf2];

        expect(
          decodeResponseText(
            bytes,
            contentType: 'text/plain; charset=windows-1251',
          ),
          'Привет',
        );
      });

      test('decodes Shift_JIS', () {
        const bytes = [0x93, 0xfa, 0x96, 0x7b];

        expect(
          decodeResponseText(
            bytes,
            contentType: 'text/plain; charset=shift_jis',
          ),
          '日本',
        );
      });

      test('decodes GBK', () {
        const bytes = [0xd6, 0xd0, 0xce, 0xc4];

        expect(
          decodeResponseText(bytes, contentType: 'text/plain; charset=gbk'),
          '中文',
        );
      });

      test('honors explicit UTF-16 endianness without a BOM', () {
        const littleEndian = [0x48, 0x00, 0x69, 0x00, 0x20, 0x00, 0xac, 0x20];
        const bigEndian = [0x00, 0x48, 0x00, 0x69, 0x00, 0x20, 0x20, 0xac];

        expect(
          decodeResponseText(
            littleEndian,
            contentType: 'text/plain; charset=utf-16le',
          ),
          'Hi €',
        );
        expect(
          decodeResponseText(
            bigEndian,
            contentType: 'text/plain; charset=utf-16be',
          ),
          'Hi €',
        );
      });

      test('honors explicit UTF-32 endianness without a BOM', () {
        const littleEndian = [
          0x48,
          0x00,
          0x00,
          0x00,
          0x69,
          0x00,
          0x00,
          0x00,
          0x20,
          0x00,
          0x00,
          0x00,
          0xac,
          0x20,
          0x00,
          0x00,
        ];
        const bigEndian = [
          0x00,
          0x00,
          0x00,
          0x48,
          0x00,
          0x00,
          0x00,
          0x69,
          0x00,
          0x00,
          0x00,
          0x20,
          0x00,
          0x00,
          0x20,
          0xac,
        ];

        expect(
          decodeResponseText(
            littleEndian,
            contentType: 'text/plain; charset=utf-32le',
          ),
          'Hi €',
        );
        expect(
          decodeResponseText(
            bigEndian,
            contentType: 'text/plain; charset=utf-32be',
          ),
          'Hi €',
        );
      });

      test('throws for unsupported charset', () {
        expect(
          () => decodeResponseText(const [
            0x66,
            0x6f,
            0x6f,
          ], contentType: 'text/plain; charset=made-up'),
          throwsA(
            isA<ResponseDecodingException>().having(
              (error) => error.message,
              'message',
              contains('Unsupported response charset: "made-up"'),
            ),
          ),
        );
      });

      test('wraps malformed encoded bytes', () {
        expect(
          () => decodeResponseText(const [
            0x81,
          ], contentType: 'text/plain; charset=windows-1252'),
          throwsA(
            isA<ResponseDecodingException>().having(
              (error) => error.message,
              'message',
              contains('Failed to decode response body'),
            ),
          ),
        );
      });

      test('throws for malformed Content-Type', () {
        expect(
          () => decodeResponseText(const [
            0x66,
            0x6f,
            0x6f,
          ], contentType: 'text/plain; charset'),
          throwsA(
            isA<ResponseDecodingException>().having(
              (error) => error.message,
              'message',
              contains('Invalid response Content-Type header'),
            ),
          ),
        );
      });

      test('does not treat GB18030 as GBK', () {
        expect(
          () => decodeResponseText(const [
            0x66,
            0x6f,
            0x6f,
          ], contentType: 'text/plain; charset=gb18030'),
          throwsA(isA<ResponseDecodingException>()),
        );
      });

      test('does not use the broken EUC-KR decoder', () {
        for (final charsetName in ['euc-kr', 'cp949']) {
          expect(
            () => decodeResponseText(const [
              0xc7,
              0xd1,
              0xb1,
              0xb9,
            ], contentType: 'text/plain; charset=$charsetName'),
            throwsA(
              isA<ResponseDecodingException>().having(
                (error) => error.message,
                'message',
                contains('Unsupported response charset: "$charsetName"'),
              ),
            ),
          );
        }
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
