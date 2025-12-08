import 'package:test/test.dart';
import 'package:tonik_core/src/transformer/config_transformer.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/properties', () {
    test('applies property overrides and does not duplicate properties', () {
      final ctx = Context.initial();

      final idProperty = Property(
        name: 'petId',
        model: IntegerModel(context: ctx.push('Pet').push('petId')),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );

      final nameProperty = Property(
        name: 'name',
        model: StringModel(context: ctx.push('Pet').push('name')),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );

      final petModel = ClassModel(
        name: 'Pet',
        properties: [idProperty, nameProperty],
        context: ctx.push('Pet'),
        isDeprecated: false,
      );

      final apiDocument = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {petModel},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      const config = TonikConfig(
        nameOverrides: NameOverridesConfig(properties: {'Pet.petId': 'id'}),
      );

      const transformer = ConfigTransformer();
      final transformed = transformer.apply(apiDocument, config);

      final transformedPet = transformed.models
          .whereType<ClassModel>()
          .firstWhere((m) => m.name == 'Pet');

      expect(transformedPet.properties, hasLength(2));

      final transformedId = transformedPet.properties.firstWhere(
        (p) => p.name == 'petId',
      );
      expect(transformedId.nameOverride, 'id');
      expect(identical(transformedId, idProperty), isTrue);

      final transformedName = transformedPet.properties.firstWhere(
        (p) => p.name == 'name',
      );
      expect(transformedName.nameOverride, isNull);
      expect(identical(transformedName, nameProperty), isTrue);
    });
  });
}
