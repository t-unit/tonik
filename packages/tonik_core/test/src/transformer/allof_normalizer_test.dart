import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('AllOfNormalizer', () {
    late AllOfNormalizer normalizer;
    late Context context;

    setUp(() {
      normalizer = const AllOfNormalizer();
      context = Context.initial();
    });

    group('normalization', () {
      test('converts AllOfModel with single ref to AliasModel', () {
        final baseModel = ClassModel(
          name: 'BaseModel',
          properties: const [],
          context: context.push('BaseModel'),
          isDeprecated: false,
        );

        final allOfModel = AllOfModel(
          name: 'ExtendedModel',
          models: {baseModel},
          context: context.push('ExtendedModel'),
          description: 'Additional documentation',
          isDeprecated: false,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {baseModel, allOfModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        final extendedModel = transformed.models.firstWhere(
          (m) => m is NamedModel && m.name == 'ExtendedModel',
        );

        expect(extendedModel, isA<AliasModel>());
        final alias = extendedModel as AliasModel;
        expect(alias.model, isA<ClassModel>());
        expect((alias.model as ClassModel).name, equals('BaseModel'));
        expect(alias.description, equals('Additional documentation'));
        expect(alias.isDeprecated, isFalse);
      });

      test('preserves deprecated flag from AllOfModel', () {
        final baseModel = StringModel(context: context);

        final allOfModel = AllOfModel(
          name: 'DeprecatedAlias',
          models: {baseModel},
          context: context.push('DeprecatedAlias'),
          description: 'This is deprecated',
          isDeprecated: true,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {allOfModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        final model = transformed.models.first as AliasModel;
        expect(model.isDeprecated, isTrue);
        expect(model.description, equals('This is deprecated'));
      });

      test('preserves nullable flag from AllOfModel', () {
        final baseModel = IntegerModel(context: context);

        final allOfModel = AllOfModel(
          name: 'NullableAlias',
          models: {baseModel},
          context: context.push('NullableAlias'),
          isDeprecated: false,
          isNullable: true,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {allOfModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        final model = transformed.models.first as AliasModel;
        expect(model.isNullable, isTrue);
      });

      test('normalizes anonymous AllOfModel with single model', () {
        final baseModel = NumberModel(context: context);

        final allOfModel = AllOfModel(
          models: {baseModel},
          context: context.push('allOf'),
          isDeprecated: false,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {allOfModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        // Anonymous single-model AllOfModels ARE normalized to AliasModel
        final model = transformed.models.first as AliasModel;
        expect(model.name, isNull);
        expect(model.model, isA<NumberModel>());
      });
    });

    group('does not normalize', () {
      test('AllOfModel with multiple models', () {
        final model1 = ClassModel(
          name: 'Model1',
          properties: const [],
          context: context.push('Model1'),
          isDeprecated: false,
        );

        final model2 = ClassModel(
          name: 'Model2',
          properties: const [],
          context: context.push('Model2'),
          isDeprecated: false,
        );

        final allOfModel = AllOfModel(
          name: 'CompositeModel',
          models: {model1, model2},
          context: context.push('CompositeModel'),
          isDeprecated: false,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {model1, model2, allOfModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        final composite = transformed.models.firstWhere(
          (m) => m is NamedModel && m.name == 'CompositeModel',
        );

        expect(composite, isA<AllOfModel>());
        expect((composite as AllOfModel).models, hasLength(2));
      });

      test('non-AllOfModel remains unchanged', () {
        final classModel = ClassModel(
          name: 'RegularModel',
          properties: const [],
          context: context.push('RegularModel'),
          isDeprecated: false,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {classModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        expect(transformed.models.first, isA<ClassModel>());
        expect((transformed.models.first as ClassModel).name, 'RegularModel');
      });

      test('AliasModel remains unchanged', () {
        final baseModel = StringModel(context: context);

        final aliasModel = AliasModel(
          name: 'ExistingAlias',
          model: baseModel,
          context: context.push('ExistingAlias'),
          description: 'Already an alias',
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {aliasModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        expect(transformed.models.first, isA<AliasModel>());
        expect((transformed.models.first as AliasModel).name, 'ExistingAlias');
        expect(
          (transformed.models.first as AliasModel).description,
          'Already an alias',
        );
      });
    });

    group('handles nested references', () {
      test('normalizes AllOfModel containing another AliasModel', () {
        final baseModel = BooleanModel(context: context);

        final innerAlias = AliasModel(
          name: 'InnerAlias',
          model: baseModel,
          context: context.push('InnerAlias'),
        );

        final outerAllOf = AllOfModel(
          name: 'OuterAllOf',
          models: {innerAlias},
          context: context.push('OuterAllOf'),
          description: 'Wraps an alias',
          isDeprecated: false,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {innerAlias, outerAllOf},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        final outer = transformed.models.firstWhere(
          (m) => m is NamedModel && m.name == 'OuterAllOf',
        );

        expect(outer, isA<AliasModel>());
        final outerAlias = outer as AliasModel;
        expect(outerAlias.model, isA<AliasModel>());
        expect((outerAlias.model as AliasModel).name, equals('InnerAlias'));
        expect(outerAlias.description, equals('Wraps an alias'));
      });
    });

    group('edge cases', () {
      test('returns document unchanged when no AllOfModels present', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {
            StringModel(context: context),
            IntegerModel(context: context),
          },
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        expect(transformed.models.length, equals(document.models.length));
      });

      test('handles empty models set', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        expect(transformed.models, isEmpty);
      });
    });

    group('deep transformation', () {
      test('normalizes AllOfModel in property and updates references', () {
        final baseModel = ClassModel(
          name: 'ExternalUrlObject',
          properties: const [],
          context: context.push('ExternalUrlObject'),
          isDeprecated: false,
        );

        final allOfModel = AllOfModel(
          name: 'ArtistObjectExternalUrlsAllOfModel',
          models: {baseModel},
          context: context.push('ArtistObjectExternalUrlsAllOfModel'),
          description: 'Known external URLs for this artist.',
          isDeprecated: false,
        );

        final classModel = ClassModel(
          name: 'ArtistObject',
          properties: [
            Property(
              name: 'externalUrls',
              model: allOfModel,
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context.push('ArtistObject'),
          isDeprecated: false,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {baseModel, allOfModel, classModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        // The AllOfModel in document.models should be normalized to AliasModel
        final normalizedAllOf =
            transformed.models.firstWhere(
                  (m) =>
                      m is NamedModel &&
                      m.name == 'ArtistObjectExternalUrlsAllOfModel',
                )
                as AliasModel;
        expect(
          normalizedAllOf.name,
          equals('ArtistObjectExternalUrlsAllOfModel'),
        );
        expect(normalizedAllOf.model, isA<ClassModel>());
        expect(
          normalizedAllOf.description,
          equals('Known external URLs for this artist.'),
        );

        // The ClassModel's property should also reference the transformed model
        final artist =
            transformed.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'ArtistObject',
                )
                as ClassModel;
        final externalUrlsProp = artist.properties.first;
        // Property should now reference the AliasModel, not the original
        // AllOfModel
        expect(externalUrlsProp.model, isA<AliasModel>());
        expect(
          (externalUrlsProp.model as AliasModel).name,
          equals('ArtistObjectExternalUrlsAllOfModel'),
        );
      });

      test('normalizes AllOfModel within ListModel content', () {
        final baseModel = ClassModel(
          name: 'ItemModel',
          properties: const [],
          context: context.push('ItemModel'),
          isDeprecated: false,
        );

        final allOfModel = AllOfModel(
          name: 'ItemsAllOfModel',
          models: {baseModel},
          context: context.push('ItemsAllOfModel'),
          description: 'Collection items',
          isDeprecated: false,
        );

        final listModel = ListModel(
          content: allOfModel,
          context: context.push('ItemList'),
          name: 'ItemList',
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {baseModel, allOfModel, listModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        // AllOfModel should be normalized
        final normalizedAllOf =
            transformed.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'ItemsAllOfModel',
                )
                as AliasModel;
        expect(normalizedAllOf.model, isA<ClassModel>());

        // ListModel's content should also be the AliasModel
        final list =
            transformed.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'ItemList',
                )
                as ListModel;
        expect(list.content, isA<AliasModel>());
        expect((list.content as AliasModel).name, equals('ItemsAllOfModel'));
      });

      test('normalizes nested AllOfModel inside AllOfModel', () {
        final baseModel = ClassModel(
          name: 'BaseModel',
          properties: const [],
          context: context.push('BaseModel'),
          isDeprecated: false,
        );

        final innerAllOf = AllOfModel(
          name: 'InnerAllOf',
          models: {baseModel},
          context: context.push('InnerAllOf'),
          description: 'Inner model',
          isDeprecated: false,
        );

        final outerAllOf = AllOfModel(
          name: 'OuterAllOf',
          models: {innerAllOf},
          context: context.push('OuterAllOf'),
          description: 'Outer model',
          isDeprecated: false,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {baseModel, innerAllOf, outerAllOf},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        // Both should be normalized since they have single models
        final outer =
            transformed.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'OuterAllOf',
                )
                as AliasModel;
        expect(outer.description, equals('Outer model'));

        final inner =
            transformed.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'InnerAllOf',
                )
                as AliasModel;
        expect(inner.name, equals('InnerAllOf'));
        expect(inner.model, isA<ClassModel>());

        // Outer's model should reference the normalized inner AliasModel
        expect(outer.model, isA<AliasModel>());
        expect((outer.model as AliasModel).name, equals('InnerAllOf'));
      });

      test('preserves multi-model AllOf within properties', () {
        final baseModel1 = ClassModel(
          name: 'BaseModel1',
          properties: const [],
          context: context.push('BaseModel1'),
          isDeprecated: false,
        );

        final baseModel2 = ClassModel(
          name: 'BaseModel2',
          properties: const [],
          context: context.push('BaseModel2'),
          isDeprecated: false,
        );

        final multiAllOf = AllOfModel(
          name: 'MultiAllOf',
          models: {baseModel1, baseModel2},
          context: context.push('MultiAllOf'),
          description: 'Composition of multiple models',
          isDeprecated: false,
        );

        final classModel = ClassModel(
          name: 'ContainerModel',
          properties: [
            Property(
              name: 'composite',
              model: multiAllOf,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context.push('ContainerModel'),
          isDeprecated: false,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {baseModel1, baseModel2, multiAllOf, classModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        final container =
            transformed.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'ContainerModel',
                )
                as ClassModel;

        // Multi-model AllOf should NOT be normalized
        expect(container.properties.first.model, isA<AllOfModel>());
        final allOfProp = container.properties.first.model as AllOfModel;
        expect(allOfProp.models.length, equals(2));
      });

      test('uses memoization to ensure referential consistency', () {
        // A model referenced from multiple places
        final sharedModel = ClassModel(
          name: 'SharedModel',
          properties: const [],
          context: context.push('SharedModel'),
          isDeprecated: false,
        );

        final allOf1 = AllOfModel(
          name: 'Wrapper1',
          models: {sharedModel},
          context: context.push('Wrapper1'),
          isDeprecated: false,
        );

        final allOf2 = AllOfModel(
          name: 'Wrapper2',
          models: {sharedModel},
          context: context.push('Wrapper2'),
          isDeprecated: false,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {sharedModel, allOf1, allOf2},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);

        final alias1 =
            transformed.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'Wrapper1',
                )
                as AliasModel;
        final alias2 =
            transformed.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'Wrapper2',
                )
                as AliasModel;

        // Both should reference the same transformed ClassModel instance
        expect(identical(alias1.model, alias2.model), isTrue);
      });
    });
  });
}
