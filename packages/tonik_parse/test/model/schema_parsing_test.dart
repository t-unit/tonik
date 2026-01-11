import 'package:test/test.dart';
import 'package:tonik_parse/src/model/schema.dart';

void main() {
  group('Schema contentEncoding parsing', () {
    test('parses contentEncoding field from JSON', () {
      final json = {
        'type': 'string',
        'contentEncoding': 'base64',
      };

      final schema = Schema.fromJson(json);

      expect(schema.contentEncoding, 'base64');
      expect(schema.type, ['string']);
    });

    test('parses null contentEncoding when not present', () {
      final json = {
        'type': 'string',
      };

      final schema = Schema.fromJson(json);

      expect(schema.contentEncoding, isNull);
    });

    test('parses contentEncoding with base64url', () {
      final json = {
        'type': 'string',
        'contentEncoding': 'base64url',
      };

      final schema = Schema.fromJson(json);

      expect(schema.contentEncoding, 'base64url');
    });

    test('parses contentEncoding with quoted-printable', () {
      final json = {
        'type': 'string',
        'contentEncoding': 'quoted-printable',
      };

      final schema = Schema.fromJson(json);

      expect(schema.contentEncoding, 'quoted-printable');
    });
  });

  group('Schema contentMediaType parsing', () {
    test('parses contentMediaType field from JSON', () {
      final json = {
        'type': 'string',
        'contentMediaType': 'application/octet-stream',
      };

      final schema = Schema.fromJson(json);

      expect(schema.contentMediaType, 'application/octet-stream');
      expect(schema.type, ['string']);
    });

    test('parses null contentMediaType when not present', () {
      final json = {
        'type': 'string',
      };

      final schema = Schema.fromJson(json);

      expect(schema.contentMediaType, isNull);
    });

    test('parses contentMediaType with image type', () {
      final json = {
        'type': 'string',
        'contentMediaType': 'image/png',
      };

      final schema = Schema.fromJson(json);

      expect(schema.contentMediaType, 'image/png');
    });
  });

  group('Schema contentEncoding and contentMediaType together', () {
    test('parses both fields when present', () {
      final json = {
        'type': 'string',
        'contentEncoding': 'base64',
        'contentMediaType': 'image/png',
      };

      final schema = Schema.fromJson(json);

      expect(schema.contentEncoding, 'base64');
      expect(schema.contentMediaType, 'image/png');
      expect(schema.type, ['string']);
    });

    test('parses contentEncoding without contentMediaType', () {
      final json = {
        'type': 'string',
        'contentEncoding': 'base64',
      };

      final schema = Schema.fromJson(json);

      expect(schema.contentEncoding, 'base64');
      expect(schema.contentMediaType, isNull);
    });

    test('parses contentMediaType without contentEncoding', () {
      final json = {
        'type': 'string',
        'contentMediaType': 'application/json',
      };

      final schema = Schema.fromJson(json);

      expect(schema.contentEncoding, isNull);
      expect(schema.contentMediaType, 'application/json');
    });
  });
}
