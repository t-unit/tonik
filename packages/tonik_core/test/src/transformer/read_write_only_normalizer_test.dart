import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

ApiDocument _buildDocument({required Set<Model> models}) {
  return ApiDocument(
    title: 'Test API',
    version: '1.0.0',
    models: models,
    responseHeaders: const {},
    requestHeaders: const {},
    servers: const {},
    operations: const {},
    responses: const {},
    queryParameters: const {},
    pathParameters: const {},
    cookieParameters: const {},
    requestBodies: const {},
  );
}

void main() {
  group('ReadWriteOnlyNormalizer', () {
    late ReadWriteOnlyNormalizer normalizer;
    late Context context;

    setUp(() {
      normalizer = const ReadWriteOnlyNormalizer();
      context = Context.initial();
    });

    group('writeOnly properties', () {
      test('makes required writeOnly properties non-required', () {
        final model = ClassModel(
          name: 'User',
          context: context.push('User'),
          isDeprecated: false,
          properties: [
            Property(
              name: 'username',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'password',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isWriteOnly: true,
            ),
          ],
        );

        final document = _buildDocument(models: {model});
        normalizer.apply(document);

        final transformed = document.models.first as ClassModel;
        final username = transformed.properties.firstWhere(
          (p) => p.name == 'username',
        );
        final password = transformed.properties.firstWhere(
          (p) => p.name == 'password',
        );

        expect(username.isRequired, isTrue);
        expect(password.isRequired, isFalse);
      });

      test('does not change already non-required writeOnly properties', () {
        final model = ClassModel(
          name: 'Profile',
          context: context.push('Profile'),
          isDeprecated: false,
          properties: [
            Property(
              name: 'bio',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              isWriteOnly: true,
            ),
          ],
        );

        final document = _buildDocument(models: {model});
        normalizer.apply(document);

        final transformed = document.models.first as ClassModel;
        final bio = transformed.properties.first;

        expect(bio.isRequired, isFalse);
        expect(bio.isNullable, isTrue);
      });

      test('preserves writeOnly flag after normalization', () {
        final model = ClassModel(
          name: 'Credentials',
          context: context.push('Credentials'),
          isDeprecated: false,
          properties: [
            Property(
              name: 'secret',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isWriteOnly: true,
            ),
          ],
        );

        final document = _buildDocument(models: {model});
        normalizer.apply(document);

        final transformed = document.models.first as ClassModel;
        final secret = transformed.properties.first;

        expect(secret.isWriteOnly, isTrue);
        expect(secret.isRequired, isFalse);
      });
    });

    group('readOnly properties', () {
      test('makes required readOnly properties non-required', () {
        final model = ClassModel(
          name: 'AuditEntry',
          context: context.push('AuditEntry'),
          isDeprecated: false,
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isReadOnly: true,
            ),
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final document = _buildDocument(models: {model});
        normalizer.apply(document);

        final transformed = document.models.first as ClassModel;
        final id = transformed.properties.firstWhere(
          (p) => p.name == 'id',
        );
        final name = transformed.properties.firstWhere(
          (p) => p.name == 'name',
        );

        expect(id.isRequired, isFalse);
        expect(name.isRequired, isTrue);
      });

      test('preserves readOnly flag after normalization', () {
        final model = ClassModel(
          name: 'Record',
          context: context.push('Record'),
          isDeprecated: false,
          properties: [
            Property(
              name: 'createdAt',
              model: DateTimeModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isReadOnly: true,
            ),
          ],
        );

        final document = _buildDocument(models: {model});
        normalizer.apply(document);

        final transformed = document.models.first as ClassModel;
        final createdAt = transformed.properties.first;

        expect(createdAt.isReadOnly, isTrue);
        expect(createdAt.isRequired, isFalse);
      });
    });

    group('mixed properties', () {
      test('normalizes both readOnly and writeOnly in same model', () {
        final model = ClassModel(
          name: 'User',
          context: context.push('User'),
          isDeprecated: false,
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isReadOnly: true,
            ),
            Property(
              name: 'email',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'password',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isWriteOnly: true,
            ),
          ],
        );

        final document = _buildDocument(models: {model});
        normalizer.apply(document);

        final transformed = document.models.first as ClassModel;
        final id = transformed.properties.firstWhere(
          (p) => p.name == 'id',
        );
        final email = transformed.properties.firstWhere(
          (p) => p.name == 'email',
        );
        final password = transformed.properties.firstWhere(
          (p) => p.name == 'password',
        );

        expect(id.isRequired, isFalse);
        expect(email.isRequired, isTrue);
        expect(password.isRequired, isFalse);
      });

      test('does not modify properties without readOnly or writeOnly', () {
        final model = ClassModel(
          name: 'Simple',
          context: context.push('Simple'),
          isDeprecated: false,
          properties: [
            Property(
              name: 'title',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
        );

        final document = _buildDocument(models: {model});
        normalizer.apply(document);

        final transformed = document.models.first as ClassModel;
        final title = transformed.properties.firstWhere(
          (p) => p.name == 'title',
        );
        final count = transformed.properties.firstWhere(
          (p) => p.name == 'count',
        );

        expect(title.isRequired, isTrue);
        expect(count.isRequired, isFalse);
      });
    });

    group('nested models', () {
      test('normalizes properties in models referenced by other models', () {
        final innerModel = ClassModel(
          name: 'Address',
          context: context.push('Address'),
          isDeprecated: false,
          properties: [
            Property(
              name: 'internalId',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isReadOnly: true,
            ),
          ],
        );

        final outerModel = ClassModel(
          name: 'User',
          context: context.push('User'),
          isDeprecated: false,
          properties: [
            Property(
              name: 'address',
              model: innerModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'token',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isWriteOnly: true,
            ),
          ],
        );

        final document = _buildDocument(models: {innerModel, outerModel});
        normalizer.apply(document);

        final innerTransformed =
            document.models.firstWhere(
                  (m) => m is ClassModel && m.name == 'Address',
                )
                as ClassModel;
        final outerTransformed =
            document.models.firstWhere(
                  (m) => m is ClassModel && m.name == 'User',
                )
                as ClassModel;

        expect(
          innerTransformed.properties.first.isRequired,
          isFalse,
        );
        expect(
          outerTransformed.properties
              .firstWhere((p) => p.name == 'token')
              .isRequired,
          isFalse,
        );
        // Regular property remains required.
        expect(
          outerTransformed.properties
              .firstWhere((p) => p.name == 'address')
              .isRequired,
          isTrue,
        );
      });
    });

    group('non-class models', () {
      test('does not affect non-class models', () {
        final stringModel = StringModel(context: context);
        final listModel = ListModel(
          name: 'StringList',
          content: stringModel,
          context: context.push('StringList'),
        );

        final document = _buildDocument(models: {stringModel, listModel});
        normalizer.apply(document);

        // No exception thrown, models unchanged.
        expect(document.models, hasLength(2));
      });
    });
  });
}
