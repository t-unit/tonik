import 'package:test/test.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/response.dart';
import 'package:tonik_parse/src/model/schema.dart';

void main() {
  group('Reference', () {
    group(r'fromJson with $ref siblings', () {
      test('parses description sibling from reference', () {
        final json = {
          r'$ref': '#/components/responses/SimpleResponse',
          'description': 'Override description',
        };

        final reference = ReferenceWrapper<Response>.fromJson(json);

        expect(reference, isA<Reference<Response>>());
        final ref = reference as Reference<Response>;
        expect(ref.ref, '#/components/responses/SimpleResponse');
        expect(ref.description, 'Override description');
        expect(ref.summary, isNull);
      });

      test('parses summary sibling from reference', () {
        final json = {
          r'$ref': '#/components/responses/SimpleResponse',
          'summary': 'Override summary',
        };

        final reference = ReferenceWrapper<Response>.fromJson(json);

        expect(reference, isA<Reference<Response>>());
        final ref = reference as Reference<Response>;
        expect(ref.ref, '#/components/responses/SimpleResponse');
        expect(ref.description, isNull);
        expect(ref.summary, 'Override summary');
      });

      test('parses both description and summary siblings from reference', () {
        final json = {
          r'$ref': '#/components/responses/SimpleResponse',
          'description': 'Override description',
          'summary': 'Override summary',
        };

        final reference = ReferenceWrapper<Response>.fromJson(json);

        expect(reference, isA<Reference<Response>>());
        final ref = reference as Reference<Response>;
        expect(ref.ref, '#/components/responses/SimpleResponse');
        expect(ref.description, 'Override description');
        expect(ref.summary, 'Override summary');
      });

      test('parses reference without description sibling', () {
        final json = {
          r'$ref': '#/components/responses/SimpleResponse',
        };

        final reference = ReferenceWrapper<Response>.fromJson(json);

        expect(reference, isA<Reference<Response>>());
        final ref = reference as Reference<Response>;
        expect(ref.ref, '#/components/responses/SimpleResponse');
        expect(ref.description, isNull);
      });

      test('ignores other sibling properties per OAS spec', () {
        // Per OAS 3.1 spec, only summary and description are valid siblings.
        // Other properties should be ignored.
        final json = {
          r'$ref': '#/components/responses/SimpleResponse',
          'description': 'Override description',
          'someOtherProperty': 'ignored',
        };

        final reference = ReferenceWrapper<Response>.fromJson(json);

        expect(reference, isA<Reference<Response>>());
        final ref = reference as Reference<Response>;
        expect(ref.ref, '#/components/responses/SimpleResponse');
        expect(ref.description, 'Override description');
      });
    });

    group('Boolean schemas (OAS 3.1 / JSON Schema 2020-12)', () {
      test('parses boolean true as Schema', () {
        final reference = ReferenceWrapper<Schema>.fromJson(true);

        expect(reference, isA<InlinedObject<Schema>>());
        final inlined = reference as InlinedObject<Schema>;
        expect(inlined.object, isA<Schema>());
        expect(inlined.object.isBooleanSchema, true);
      });

      test('parses boolean false as Schema', () {
        final reference = ReferenceWrapper<Schema>.fromJson(false);

        expect(reference, isA<InlinedObject<Schema>>());
        final inlined = reference as InlinedObject<Schema>;
        expect(inlined.object, isA<Schema>());
        expect(inlined.object.isBooleanSchema, false);
      });

      test('throws FormatException for boolean with non-Schema type', () {
        expect(
          () => ReferenceWrapper<Response>.fromJson(true),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Boolean schemas are only supported for Schema types'),
            ),
          ),
        );

        expect(
          () => ReferenceWrapper<Response>.fromJson(false),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Boolean schemas are only supported for Schema types'),
            ),
          ),
        );
      });
    });
  });
}
