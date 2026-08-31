import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('RequestBody', () {
    late Context context;

    setUp(() {
      context = Context.initial();
    });

    test('ordinary content owns its model and rejects multipart category', () {
      final model = StringModel(context: context);
      final content = ModelRequestContent(
        model: model,
        contentType: ContentType.json,
        rawContentType: 'application/json',
        examples: const [],
      );
      expect(content.model, same(model));
      expect(
        () => ModelRequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        throwsArgumentError,
      );
    });

    test('multipart content owns ordered parts with effective defaults', () {
      final alias = AliasModel(
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: 'guest',
      );
      final parts = [
        for (final name in ['label', 'title'])
          MultipartPart(
            name: name,
            model: alias,
            encoding: const PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
      ];
      final content = MultipartRequestContent(
        parts: parts,
        context: context,
        rawContentType: 'multipart/form-data',
        examples: const [],
      );
      expect(content.contentType, ContentType.multipart);
      expect(content.parts.map((part) => part.name), ['label', 'title']);
      expect(content.parts.first.model, same(alias));
      expect(content.parts.first.effectiveDefaultValue, 'guest');
      content.parts.first.defaultValue = 'local';
      expect(content.parts.first.effectiveDefaultValue, 'local');
    });

    group('contentCount', () {
      test('RequestBodyObject - returns number of content objects', () {
        final body = RequestBodyObject(
          name: 'test',
          context: context,
          description: '',
          isRequired: true,
          content: {
            ModelRequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            ModelRequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/vnd.api+json',
              examples: const [],
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
            ModelRequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
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
          ModelRequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/json',
            examples: const [],
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
          ModelRequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/json',
            examples: const [],
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
