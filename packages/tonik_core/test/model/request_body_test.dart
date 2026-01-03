import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('RequestBody', () {
    late Context context;

    setUp(() {
      context = Context.initial();
    });

    group('contentCount', () {
      test('RequestBodyObject - returns number of content objects', () {
        final body = RequestBodyObject(
          name: 'test',
          context: context,
          description: '',
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/vnd.api+json',
            ),
          },
        );

        expect(body.contentCount, 2);
      });

      test('RequestBodyObject - returns 0 for empty content set', () {
        final body = RequestBodyObject(
          name: 'test',
          context: context,
          description: '',
          isRequired: true,
          content: const {},
        );

        expect(body.contentCount, 0);
      });

      test('RequestBodyAlias - returns content count of referenced body', () {
        final referencedBody = RequestBodyObject(
          name: 'referenced',
          context: context,
          description: '',
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
          },
        );

        final alias = RequestBodyAlias(
          name: 'test',
          context: context,
          requestBody: referencedBody,
        );

        expect(alias.contentCount, 1);
      });
    });

    group('resolvedContent', () {
      test('RequestBodyObject - returns its own content', () {
        final content = {
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/json',
          ),
        };

        final body = RequestBodyObject(
          name: 'test',
          context: context,
          description: '',
          isRequired: true,
          content: content,
        );

        expect(body.resolvedContent, content);
      });

      test('RequestBodyAlias - returns content of referenced body', () {
        final content = {
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/json',
          ),
        };

        final referencedBody = RequestBodyObject(
          name: 'referenced',
          context: context,
          description: '',
          isRequired: true,
          content: content,
        );

        final alias = RequestBodyAlias(
          name: 'test',
          context: context,
          requestBody: referencedBody,
        );

        expect(alias.resolvedContent, content);
      });
    });

    group('description override', () {
      test('RequestBodyAlias stores description override', () {
        final referencedBody = RequestBodyObject(
          name: 'original',
          context: context,
          description: 'Original description',
          isRequired: true,
          content: const {},
        );

        final alias = RequestBodyAlias(
          name: 'aliased',
          context: context,
          requestBody: referencedBody,
          description: 'Overridden description',
        );

        expect(alias.description, 'Overridden description');
      });

      test('RequestBodyAlias description is null when not overridden', () {
        final referencedBody = RequestBodyObject(
          name: 'original',
          context: context,
          description: 'Original description',
          isRequired: true,
          content: const {},
        );

        final alias = RequestBodyAlias(
          name: 'aliased',
          context: context,
          requestBody: referencedBody,
        );

        expect(alias.description, isNull);
      });
    });
  });
}
