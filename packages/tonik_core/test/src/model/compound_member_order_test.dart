import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  test('normalization preserves compound member order and duplicates', () {
    final context = Context.initial();
    final zebra = ClassModel(
      name: 'Zebra',
      context: context.push('Zebra'),
      properties: const [],
      isDeprecated: false,
      examples: const [],
    );
    final alpha = ClassModel(
      name: 'Alpha',
      context: context.push('Alpha'),
      properties: const [],
      isDeprecated: false,
      examples: const [],
    );
    final wrapped = AllOfModel(
      name: 'Wrapped',
      context: context.push('Wrapped'),
      models: [zebra],
      isDeprecated: false,
      examples: const [],
    );
    final allOf = AllOfModel(
      name: 'All',
      context: context.push('All'),
      models: [wrapped, alpha, zebra, zebra],
      isDeprecated: false,
      examples: const [],
    );
    final oneOf = OneOfModel(
      name: 'One',
      context: context.push('One'),
      models: <DiscriminatedModel>[
        (model: wrapped, discriminatorValue: 'z'),
        (model: alpha, discriminatorValue: 'a'),
        (model: zebra, discriminatorValue: 'again'),
        (model: zebra, discriminatorValue: 'again'),
      ],
      isDeprecated: false,
      examples: const [],
    );
    final anyOf = AnyOfModel(
      name: 'Any',
      context: context.push('Any'),
      models: <DiscriminatedModel>[
        (model: wrapped, discriminatorValue: 'z'),
        (model: alpha, discriminatorValue: 'a'),
        (model: zebra, discriminatorValue: 'again'),
        (model: zebra, discriminatorValue: 'again'),
      ],
      isDeprecated: false,
      examples: const [],
    );
    expect(allOf.models, isA<List<Model>>());
    expect(oneOf.models, isA<List<DiscriminatedModel>>());
    expect(anyOf.models, isA<List<DiscriminatedModel>>());
    expect(allOf.models, [wrapped, alpha, zebra, zebra]);
    expect(oneOf.models, <DiscriminatedModel>[
      (model: wrapped, discriminatorValue: 'z'),
      (model: alpha, discriminatorValue: 'a'),
      (model: zebra, discriminatorValue: 'again'),
      (model: zebra, discriminatorValue: 'again'),
    ]);
    expect(anyOf.models, <DiscriminatedModel>[
      (model: wrapped, discriminatorValue: 'z'),
      (model: alpha, discriminatorValue: 'a'),
      (model: zebra, discriminatorValue: 'again'),
      (model: zebra, discriminatorValue: 'again'),
    ]);

    final document = ApiDocument(
      title: 'Test',
      version: '1',
      models: {zebra, alpha, wrapped, allOf, oneOf, anyOf},
      requestBodies: const {},
      responseHeaders: const {},
      requestHeaders: const {},
      servers: const {},
      operations: const {},
      responses: const {},
      queryParameters: const {},
      pathParameters: const {},
      cookieParameters: const {},
    );
    const AllOfNormalizer().apply(document);
    final normalized = document.models.whereType<AliasModel>().singleWhere(
      (m) => m.name == 'Wrapped',
    );
    expect(normalized.model, same(zebra));
    expect(allOf.models, [normalized, alpha, zebra, zebra]);
    expect(oneOf.models.map((m) => m.model), [normalized, alpha, zebra, zebra]);
    expect(anyOf.models.map((m) => m.model), [normalized, alpha, zebra, zebra]);
    expect(oneOf.models.map((m) => m.discriminatorValue), [
      'z',
      'a',
      'again',
      'again',
    ]);
    expect(anyOf.models.map((m) => m.discriminatorValue), [
      'z',
      'a',
      'again',
      'again',
    ]);
  });
}
