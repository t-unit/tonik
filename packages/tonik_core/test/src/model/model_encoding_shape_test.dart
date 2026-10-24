import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  final context = Context.initial();

  test('oneOf and allOf cycle has mixed encoding and terminates helpers', () {
    final pet = OneOfModel(
      models: [],
      context: context,
      isDeprecated: false,
      examples: const [],
      name: 'Pet',
      nameOverride: null,
      description: null,
      discriminator: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );
    final details = ClassModel(
      properties: const [],
      context: context,
      isDeprecated: false,
      examples: const [],
      name: 'Details',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final cat = AllOfModel(
      models: [pet, details],
      context: context,
      isDeprecated: false,
      examples: const [],
      name: 'Cat',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );
    pet.models.add((model: cat, discriminatorValue: null));

    expect(pet.encodingShape, EncodingShape.mixed);
    expect(cat.encodingShape, EncodingShape.mixed);
    expect(pet.hasSimpleTypes, isFalse);
    expect(pet.hasComplexTypes, isFalse);
    expect(pet.hasMixedTypes, isTrue);
    expect(pet.cannotBeSimplyEncoded, isTrue);
    expect(cat.hasSimpleTypes, isFalse);
    expect(cat.hasComplexTypes, isTrue);
    expect(cat.hasMixedTypes, isTrue);
    expect(cat.cannotBeSimplyEncoded, isTrue);
  });

  test('self-referencing anyOf keeps simple members and reports mixed', () {
    final model = AnyOfModel(
      models: [],
      context: context,
      isDeprecated: false,
      examples: const [],
      name: 'Recursive',
      nameOverride: null,
      description: null,
      discriminator: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );
    model.models.add((model: model, discriminatorValue: null));
    model.models.add((
      model: StringModel(context: context),
      discriminatorValue: null,
    ));

    expect(model.encodingShape, EncodingShape.mixed);
    expect(model.hasSimpleTypes, isTrue);
    expect(model.hasComplexTypes, isFalse);
    expect(model.hasMixedTypes, isTrue);
    expect(model.cannotBeSimplyEncoded, isTrue);
  });

  test(
    'alias-mediated composite cycle has mixed encoding from either root',
    () {
      final composite = AllOfModel(
        models: [],
        context: context,
        isDeprecated: false,
        examples: const [],
        name: 'Recursive',
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );
      final alias = AliasModel(
        model: composite,
        context: context,
        examples: const [],
        defaultValue: null,
        name: 'Reference',
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );
      composite.models.add(alias);

      expect(composite.encodingShape, EncodingShape.mixed);
      expect(alias.encodingShape, EncodingShape.mixed);
      expect(composite.hasSimpleTypes, isFalse);
      expect(composite.hasComplexTypes, isFalse);
      expect(composite.hasMixedTypes, isTrue);
      expect(composite.cannotBeSimplyEncoded, isTrue);
    },
  );

  test(
    'repeated acyclic composite and alias children retain simple encoding',
    () {
      final child = AnyOfModel(
        models: [
          (model: StringModel(context: context), discriminatorValue: null),
        ],
        context: context,
        isDeprecated: false,
        examples: const [],
        name: 'Child',
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );
      final alias = AliasModel(
        model: child,
        context: context,
        examples: const [],
        defaultValue: null,
        name: 'Reference',
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );
      final parent = AllOfModel(
        models: [child, alias, child, alias],
        context: context,
        isDeprecated: false,
        examples: const [],
        name: 'Parent',
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      expect(parent.encodingShape, EncodingShape.simple);
      expect(alias.encodingShape, EncodingShape.simple);
      expect(parent.hasSimpleTypes, isTrue);
      expect(parent.hasComplexTypes, isFalse);
      expect(parent.hasMixedTypes, isFalse);
      expect(parent.cannotBeSimplyEncoded, isFalse);
    },
  );

  test('acyclic encoding stays current after member changes', () {
    final model = OneOfModel(
      models: [],
      context: context,
      isDeprecated: false,
      examples: const [],
      name: 'Choice',
      nameOverride: null,
      description: null,
      discriminator: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );
    final object = ClassModel(
      properties: const [],
      context: context,
      isDeprecated: false,
      examples: const [],
      name: 'Object',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );

    expect(model.encodingShape, EncodingShape.mixed);

    model.models.add((model: object, discriminatorValue: null));

    expect(model.encodingShape, EncodingShape.complex);
    expect(model.hasComplexTypes, isTrue);
    expect(model.cannotBeSimplyEncoded, isFalse);

    model.models.add((
      model: StringModel(context: context),
      discriminatorValue: null,
    ));

    expect(model.encodingShape, EncodingShape.mixed);
    expect(model.hasSimpleTypes, isTrue);
    expect(model.hasComplexTypes, isTrue);
    expect(model.hasMixedTypes, isFalse);
    expect(model.cannotBeSimplyEncoded, isTrue);
  });
}
