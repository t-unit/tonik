import 'package:test/test.dart';
import 'package:tonik_parse/src/model/schema.dart';

void main() {
  group('Schema additionalProperties parsing', () {
    test('parses additionalProperties: true as bool', () {
      final json = <String, dynamic>{
        'type': ['object'],
        'additionalProperties': true,
      };

      final schema = Schema.fromJson(json);
      expect(schema.additionalProperties, isTrue);
    });

    test('parses additionalProperties: false as bool', () {
      final json = <String, dynamic>{
        'type': ['object'],
        'additionalProperties': false,
      };

      final schema = Schema.fromJson(json);
      expect(schema.additionalProperties, isFalse);
    });

    test('parses additionalProperties as Schema when map', () {
      final json = <String, dynamic>{
        'type': ['object'],
        'additionalProperties': <String, dynamic>{
          'type': ['string'],
        },
      };

      final schema = Schema.fromJson(json);
      expect(schema.additionalProperties, isA<Schema>());
      final apSchema = schema.additionalProperties! as Schema;
      expect(apSchema.type, contains('string'));
    });

    test('parses null additionalProperties', () {
      final json = <String, dynamic>{
        'type': ['object'],
      };

      final schema = Schema.fromJson(json);
      expect(schema.additionalProperties, isNull);
    });

  });
}
