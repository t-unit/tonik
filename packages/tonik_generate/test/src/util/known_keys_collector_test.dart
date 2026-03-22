import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/known_keys_collector.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('collectKnownKeys', () {
    group('ClassModel', () {
      test('returns property names', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          context: context,
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'email',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
        );

        expect(collectKnownKeys(model), {'id', 'name', 'email'});
      });

      test('returns empty set for class with no properties', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Empty',
          context: context,
          properties: const [],
        );

        expect(collectKnownKeys(model), <String>{});
      });
    });

    group('AllOfModel', () {
      test('returns union of all member known keys', () {
        final baseModel = ClassModel(
          isDeprecated: false,
          name: 'Base',
          context: context,
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final extModel = ClassModel(
          isDeprecated: false,
          name: 'Extension',
          context: context,
          properties: [
            Property(
              name: 'extra',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final allOf = AllOfModel(
          isDeprecated: false,
          name: 'Combined',
          context: context,
          models: {baseModel, extModel},
        );

        expect(collectKnownKeys(allOf), {'id', 'extra'});
      });

      test('returns union across nested allOf models', () {
        final innerClass = ClassModel(
          isDeprecated: false,
          name: 'Inner',
          context: context,
          properties: [
            Property(
              name: 'a',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final innerAllOf = AllOfModel(
          isDeprecated: false,
          name: 'InnerAllOf',
          context: context,
          models: {innerClass},
        );

        final outerClass = ClassModel(
          isDeprecated: false,
          name: 'Outer',
          context: context,
          properties: [
            Property(
              name: 'b',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final outerAllOf = AllOfModel(
          isDeprecated: false,
          name: 'OuterAllOf',
          context: context,
          models: {innerAllOf, outerClass},
        );

        expect(collectKnownKeys(outerAllOf), {'a', 'b'});
      });

      test('returns empty set for allOf with no class members', () {
        final allOf = AllOfModel(
          isDeprecated: false,
          name: 'EmptyAllOf',
          context: context,
          models: const {},
        );

        expect(collectKnownKeys(allOf), <String>{});
      });
    });

    group('OneOfModel', () {
      test('returns discriminator key when present', () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Pet',
          context: context,
          models: const {},
          discriminator: 'petType',
        );

        expect(collectKnownKeys(model), {'petType'});
      });

      test('returns empty set when no discriminator and no variants', () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Pet',
          context: context,
          models: const {},
        );

        expect(collectKnownKeys(model), <String>{});
      });

      test('returns union of variant property keys', () {
        final cat = ClassModel(
          isDeprecated: false,
          name: 'Cat',
          context: context,
          properties: [
            Property(
              name: 'whiskerLength',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final dog = ClassModel(
          isDeprecated: false,
          name: 'Dog',
          context: context,
          properties: [
            Property(
              name: 'barkVolume',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Pet',
          context: context,
          models: {
            (discriminatorValue: 'cat', model: cat),
            (discriminatorValue: 'dog', model: dog),
          },
          discriminator: 'petType',
        );

        expect(
          collectKnownKeys(model),
          {'petType', 'whiskerLength', 'barkVolume'},
        );
      });

      test('returns variant keys even without discriminator', () {
        final cat = ClassModel(
          isDeprecated: false,
          name: 'Cat',
          context: context,
          properties: [
            Property(
              name: 'whiskerLength',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Pet',
          context: context,
          models: {
            (discriminatorValue: null, model: cat),
          },
        );

        expect(collectKnownKeys(model), {'whiskerLength'});
      });
    });

    group('AnyOfModel', () {
      test('returns discriminator key when present', () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'Content',
          context: context,
          models: const {},
          discriminator: 'contentType',
        );

        expect(collectKnownKeys(model), {'contentType'});
      });

      test('returns empty set when no discriminator and no variants', () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'Content',
          context: context,
          models: const {},
        );

        expect(collectKnownKeys(model), <String>{});
      });

      test('returns union of variant property keys', () {
        final text = ClassModel(
          isDeprecated: false,
          name: 'TextContent',
          context: context,
          properties: [
            Property(
              name: 'body',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final image = ClassModel(
          isDeprecated: false,
          name: 'ImageContent',
          context: context,
          properties: [
            Property(
              name: 'url',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'Content',
          context: context,
          models: {
            (discriminatorValue: 'text', model: text),
            (discriminatorValue: 'image', model: image),
          },
          discriminator: 'kind',
        );

        expect(collectKnownKeys(model), {'kind', 'body', 'url'});
      });

      test('returns variant keys even without discriminator', () {
        final text = ClassModel(
          isDeprecated: false,
          name: 'TextContent',
          context: context,
          properties: [
            Property(
              name: 'body',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'Content',
          context: context,
          models: {
            (discriminatorValue: null, model: text),
          },
        );

        expect(collectKnownKeys(model), {'body'});
      });
    });

    group('AliasModel', () {
      test('delegates to wrapped model', () {
        final classModel = ClassModel(
          isDeprecated: false,
          name: 'User',
          context: context,
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final alias = AliasModel(
          name: 'UserRef',
          model: classModel,
          context: context,
        );

        expect(collectKnownKeys(alias), {'name'});
      });

      test('delegates through nested aliases', () {
        final classModel = ClassModel(
          isDeprecated: false,
          name: 'User',
          context: context,
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final innerAlias = AliasModel(
          name: 'InnerAlias',
          model: classModel,
          context: context,
        );

        final outerAlias = AliasModel(
          name: 'OuterAlias',
          model: innerAlias,
          context: context,
        );

        expect(collectKnownKeys(outerAlias), {'id'});
      });
    });

    group('other model types', () {
      test('returns empty set for StringModel', () {
        expect(
          collectKnownKeys(StringModel(context: context)),
          <String>{},
        );
      });

      test('returns empty set for IntegerModel', () {
        expect(
          collectKnownKeys(IntegerModel(context: context)),
          <String>{},
        );
      });

      test('returns empty set for ListModel', () {
        final model = ListModel(
          content: StringModel(context: context),
          context: context,
        );
        expect(collectKnownKeys(model), <String>{});
      });

      test('returns empty set for MapModel', () {
        final model = MapModel(
          valueModel: StringModel(context: context),
          context: context,
        );
        expect(collectKnownKeys(model), <String>{});
      });

      test('returns empty set for EnumModel', () {
        final model = EnumModel(
          isDeprecated: false,
          name: 'Status',
          context: context,
          values: {const EnumEntry(value: 'active')},
          isNullable: false,
        );
        expect(collectKnownKeys(model), <String>{});
      });
    });

    group('allOf with oneOf/anyOf members', () {
      test('includes discriminator from oneOf member', () {
        final classModel = ClassModel(
          isDeprecated: false,
          name: 'Base',
          context: context,
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final oneOfModel = OneOfModel(
          isDeprecated: false,
          name: 'Pet',
          context: context,
          models: const {},
          discriminator: 'type',
        );

        final allOf = AllOfModel(
          isDeprecated: false,
          name: 'Combined',
          context: context,
          models: {classModel, oneOfModel},
        );

        expect(collectKnownKeys(allOf), {'id', 'type'});
      });

      test('includes discriminator from anyOf member', () {
        final classModel = ClassModel(
          isDeprecated: false,
          name: 'Base',
          context: context,
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        final anyOfModel = AnyOfModel(
          isDeprecated: false,
          name: 'Content',
          context: context,
          models: const {},
          discriminator: 'kind',
        );

        final allOf = AllOfModel(
          isDeprecated: false,
          name: 'Combined',
          context: context,
          models: {classModel, anyOfModel},
        );

        expect(collectKnownKeys(allOf), {'name', 'kind'});
      });

      test(
        'includes variant property keys from oneOf member',
        () {
          final cat = ClassModel(
            isDeprecated: false,
            name: 'Cat',
            context: context,
            properties: [
              Property(
                name: 'whiskerLength',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
          );

          final dog = ClassModel(
            isDeprecated: false,
            name: 'Dog',
            context: context,
            properties: [
              Property(
                name: 'barkVolume',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
          );

          final oneOfModel = OneOfModel(
            isDeprecated: false,
            name: 'PetVariant',
            context: context,
            models: {
              (discriminatorValue: 'cat', model: cat),
              (discriminatorValue: 'dog', model: dog),
            },
          );

          final baseModel = ClassModel(
            isDeprecated: false,
            name: 'Base',
            context: context,
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
          );

          final allOf = AllOfModel(
            isDeprecated: false,
            name: 'MyModel',
            context: context,
            models: {oneOfModel, baseModel},
          );

          expect(
            collectKnownKeys(allOf),
            {'name', 'whiskerLength', 'barkVolume'},
          );
        },
      );
    });
  });
}
