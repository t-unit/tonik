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

  group('Schema readOnly parsing', () {
    test('parses readOnly: true from JSON', () {
      final json = {
        'type': 'string',
        'readOnly': true,
      };

      final schema = Schema.fromJson(json);

      expect(schema.isReadOnly, isTrue);
    });

    test('parses readOnly: false from JSON', () {
      final json = {
        'type': 'string',
        'readOnly': false,
      };

      final schema = Schema.fromJson(json);

      expect(schema.isReadOnly, isFalse);
    });

    test('defaults to null when readOnly is not present', () {
      final json = {
        'type': 'string',
      };

      final schema = Schema.fromJson(json);

      expect(schema.isReadOnly, isNull);
    });

    test('returns null for boolean schema', () {
      final schema = Schema.fromJson(true);

      expect(schema.isReadOnly, isNull);
    });

    test('returns null for bare string schema', () {
      final schema = Schema.fromJson('string');

      expect(schema.isReadOnly, isNull);
    });
  });

  group('Schema writeOnly parsing', () {
    test('parses writeOnly: true from JSON', () {
      final json = {
        'type': 'string',
        'writeOnly': true,
      };

      final schema = Schema.fromJson(json);

      expect(schema.isWriteOnly, isTrue);
    });

    test('parses writeOnly: false from JSON', () {
      final json = {
        'type': 'string',
        'writeOnly': false,
      };

      final schema = Schema.fromJson(json);

      expect(schema.isWriteOnly, isFalse);
    });

    test('defaults to null when writeOnly is not present', () {
      final json = {
        'type': 'string',
      };

      final schema = Schema.fromJson(json);

      expect(schema.isWriteOnly, isNull);
    });

    test('returns null for boolean schema', () {
      final schema = Schema.fromJson(true);

      expect(schema.isWriteOnly, isNull);
    });

    test('returns null for bare string schema', () {
      final schema = Schema.fromJson('string');

      expect(schema.isWriteOnly, isNull);
    });
  });

  group('Schema rawDefault parsing', () {
    test('parses string default value', () {
      final schema = Schema.fromJson({'type': 'string', 'default': 'hello'});

      expect(schema.rawDefault, 'hello');
    });

    test('parses integer default value', () {
      final schema = Schema.fromJson({'type': 'integer', 'default': 42});

      expect(schema.rawDefault, 42);
    });

    test('parses boolean default value', () {
      final schema = Schema.fromJson({'type': 'boolean', 'default': true});

      expect(schema.rawDefault, isTrue);
    });

    test('parses null default value', () {
      final schema = Schema.fromJson({
        'type': 'string',
        'nullable': true,
        'default': null,
      });

      expect(schema.rawDefault, isNull);
    });

    test('absent default keyword is rawDefault null', () {
      final schema = Schema.fromJson({'type': 'string'});

      expect(schema.rawDefault, isNull);
    });

    test('parses array default value', () {
      final schema = Schema.fromJson({
        'type': 'array',
        'items': {'type': 'integer'},
        'default': [1, 2],
      });

      expect(schema.rawDefault, [1, 2]);
    });

    test('parses object default value', () {
      final schema = Schema.fromJson({
        'type': 'object',
        'properties': {
          'a': {'type': 'integer'},
        },
        'default': {'a': 1},
      });

      expect(schema.rawDefault, {'a': 1});
    });

    test(r'parses default on $ref sibling', () {
      final schema = Schema.fromJson({
        r'$ref': '#/components/schemas/Foo',
        'default': 'hello',
      });

      expect(schema.rawDefault, 'hello');
    });

    test('returns null for boolean schema', () {
      final schema = Schema.fromJson(true);

      expect(schema.rawDefault, isNull);
    });

    test('returns null for bare string schema', () {
      final schema = Schema.fromJson('string');

      expect(schema.rawDefault, isNull);
    });
  });

  group('Schema readOnly and writeOnly together', () {
    test('parses both readOnly and writeOnly from JSON', () {
      final json = {
        'type': 'string',
        'readOnly': true,
        'writeOnly': true,
      };

      final schema = Schema.fromJson(json);

      expect(schema.isReadOnly, isTrue);
      expect(schema.isWriteOnly, isTrue);
    });

    test('parses readOnly without writeOnly', () {
      final json = {
        'type': 'integer',
        'readOnly': true,
      };

      final schema = Schema.fromJson(json);

      expect(schema.isReadOnly, isTrue);
      expect(schema.isWriteOnly, isNull);
    });

    test('parses writeOnly without readOnly', () {
      final json = {
        'type': 'string',
        'writeOnly': true,
      };

      final schema = Schema.fromJson(json);

      expect(schema.isReadOnly, isNull);
      expect(schema.isWriteOnly, isTrue);
    });

    test('parses readOnly on object schema with properties', () {
      final json = {
        'type': 'object',
        'properties': {
          'id': {
            'type': 'integer',
            'readOnly': true,
          },
          'name': {
            'type': 'string',
          },
        },
      };

      final schema = Schema.fromJson(json);
      final idSchema = schema.properties!['id']!;
      final nameSchema = schema.properties!['name']!;

      expect(idSchema.isReadOnly, isTrue);
      expect(nameSchema.isReadOnly, isNull);
    });
  });
}
