import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('Response', () {
    late Context context;

    setUp(() {
      context = Context.initial();
    });

    group('isEmpty', () {
      test(
        'ResponseObject - returns true when body is null and headers are empty',
        () {
          final response = ResponseObject(
            name: 'test',
            context: context,
            headers: const {},
            description: '',
            bodies: const {},
          );

          expect(response.isEmpty, isTrue);
        },
      );

      test('ResponseObject - returns false when body is not null', () {
        final response = ResponseObject(
          name: 'test',
          context: context,
          headers: const {},
          description: '',
          bodies:  {
            ResponseBody(
              model: StringModel(context: context),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        );

        expect(response.isEmpty, isFalse);
      });

      test('ResponseObject - returns false when headers are not empty', () {
        final response = ResponseObject(
          name: 'test',
          context: context,
          headers: {
            'Content-Type': ResponseHeaderObject(
              name: 'Content-Type',
              description: '',
              isRequired: true,
              isDeprecated: false,
              explode: false,
              model: StringModel(context: context),
              encoding: ResponseHeaderEncoding.simple,
              context: context,
            ),
          },
          description: '',
          bodies: const {},
        );

        expect(response.isEmpty, isFalse);
      });

      test(
        'ResponseAlias - returns true when referenced response is empty',
        () {
          final emptyResponse = ResponseObject(
            name: 'empty',
            context: context,
            headers: const {},
            description: '',
            bodies: const {},
          );

          final alias = ResponseAlias(
            name: 'test',
            context: context,
            response: emptyResponse,
          );

          expect(alias.isEmpty, isTrue);
        },
      );

      test(
        'ResponseAlias - returns false when referenced response is not empty',
        () {
          final nonEmptyResponse = ResponseObject(
            name: 'nonEmpty',
            context: context,
            headers: {
              'Content-Type': ResponseHeaderObject(
                name: 'Content-Type',
                description: '',
                isRequired: true,
                isDeprecated: false,
                explode: false,
                model: StringModel(context: context),
                encoding: ResponseHeaderEncoding.simple,
                context: context,
              ),
            },
            description: '',
            bodies: const {},
          );

          final alias = ResponseAlias(
            name: 'test',
            context: context,
            response: nonEmptyResponse,
          );

          expect(alias.isEmpty, isFalse);
        },
      );
    });

    group('hasHeaders', () {
      test('ResponseObject - returns true when headers are not empty', () {
        final response = ResponseObject(
          name: 'test',
          context: context,
          headers: {
            'X-Test': ResponseHeaderObject(
              name: 'X-Test',
              description: '',
              isRequired: true,
              isDeprecated: false,
              explode: false,
              model: StringModel(context: context),
              encoding: ResponseHeaderEncoding.simple,
              context: context,
            ),
          },
          description: '',
          bodies: const {},
        );

        expect(response.hasHeaders, isTrue);
      });

      test('ResponseObject - returns false when headers are empty', () {
        final response = ResponseObject(
          name: 'test',
          context: context,
          headers: const {},
          description: '',
          bodies: const {},
        );

        expect(response.hasHeaders, isFalse);
      });

      test(
        'ResponseAlias - returns true when referenced response has headers',
        () {
          final responseWithHeaders = ResponseObject(
            name: 'test',
            context: context,
            headers: {
              'X-Test': ResponseHeaderObject(
                name: 'X-Test',
                description: '',
                isRequired: true,
                isDeprecated: false,
                explode: false,
                model: StringModel(context: context),
                encoding: ResponseHeaderEncoding.simple,
                context: context,
              ),
            },
            description: '',
            bodies: const {},
          );

          final alias = ResponseAlias(
            name: 'test',
            context: context,
            response: responseWithHeaders,
          );

          expect(alias.hasHeaders, isTrue);
        },
      );

      test(
        'ResponseAlias - returns false when referenced response has no headers',
        () {
          final responseWithoutHeaders = ResponseObject(
            name: 'test',
            context: context,
            headers: const {},
            description: '',
            bodies: const {},
          );

          final alias = ResponseAlias(
            name: 'test',
            context: context,
            response: responseWithoutHeaders,
          );

          expect(alias.hasHeaders, isFalse);
        },
      );
    });
  });
}
