import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

String _formatClass(Class cls) {
  final emitter = DartEmitter(useNullSafetySyntax: true);
  return DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format(cls.accept(emitter).toString());
}

void main() {
  group('ClassGenerator with useImmutableCollections', () {
    late ClassGenerator generator;
    late NameManager nameManager;
    late Context context;
    late DartEmitter emitter;

    setUp(() {
      final nameGenerator = NameGenerator();
      nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );
      generator = ClassGenerator(
        nameManager: nameManager,
        package: 'example',
        useImmutableCollections: true,
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    group('simple list property', () {
      late ClassModel model;

      setUp(() {
        model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        nameManager.prime(
          models: {model},
          responses: const {},
          requestBodies: const {},
          operations: const {},
          tags: const [],
          servers: const {},
        );
      });

      test('generates IList field type', () {
        final result = generator.generateClass(model);
        final field = result.fields.firstWhere((f) => f.name == 'tags');
        final typeRef = field.type! as TypeReference;
        expect(typeRef.symbol, 'IList');
        expect(
          typeRef.url,
          'package:fast_immutable_collections/fast_immutable_collections.dart',
        );
        expect(typeRef.types.length, 1);
        expect((typeRef.types.first as TypeReference).symbol, 'String');
      });

      test('fromJson wraps decoded list in IList constructor', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory User.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'User');
  return User(
    tags: IList(_$map[r'tags'].decodeJsonList<String>(context: r'User.tags')),
  );
}
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });

      test('toJson uses .unlock to convert IList to List', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = '''
Object? toJson() => {r'tags': tags.unlock};
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });

      test(
        'equality uses native IList equality without DeepCollectionEquality',
        () {
          final generatedClass = generator.generateClass(model);
          final code = _formatClass(generatedClass);
          const expectedBody = '''
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is User && other.tags == this.tags;
}
''';
          expect(
            collapseWhitespace(code),
            contains(collapseWhitespace(expectedBody)),
          );
        },
      );

      test('hashCode uses native IList hashCode', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = '''
int get hashCode => tags.hashCode;
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });
    });

    group('simple map property', () {
      late ClassModel model;

      setUp(() {
        model = ClassModel(
          isDeprecated: false,
          name: 'Config',
          properties: [
            Property(
              name: 'settings',
              model: MapModel(
                valueModel: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        nameManager.prime(
          models: {model},
          responses: const {},
          requestBodies: const {},
          operations: const {},
          tags: const [],
          servers: const {},
        );
      });

      test('generates IMap field type', () {
        final result = generator.generateClass(model);
        final field = result.fields.firstWhere(
          (f) => f.name == 'settings',
        );
        final typeRef = field.type! as TypeReference;
        expect(typeRef.symbol, 'IMap');
        expect(
          typeRef.url,
          'package:fast_immutable_collections/fast_immutable_collections.dart',
        );
        expect(typeRef.types.length, 2);
        expect(typeRef.types.first.symbol, 'String');
        expect((typeRef.types.last as TypeReference).symbol, 'String');
      });

      test('fromJson wraps decoded map in IMap constructor', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory Config.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'Config');
  return Config(
    settings: IMap(
      _$map[r'settings'].decodeJsonMap(
        (v) => v.decodeJsonString(context: r'Config.settings'),
        context: r'Config.settings',
      ),
    ),
  );
}
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });

      test('toJson uses .unlock to convert IMap to Map', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = '''
Object? toJson() => {r'settings': settings.unlock};
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });
    });

    group('nested list (IList<IList<String>>)', () {
      late ClassModel model;

      setUp(() {
        model = ClassModel(
          isDeprecated: false,
          name: 'Matrix',
          properties: [
            Property(
              name: 'rows',
              model: ListModel(
                content: ListModel(
                  content: StringModel(context: context),
                  context: context,
                ),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        nameManager.prime(
          models: {model},
          responses: const {},
          requestBodies: const {},
          operations: const {},
          tags: const [],
          servers: const {},
        );
      });

      test('fromJson wraps in IList at every nesting level', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory Matrix.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'Matrix');
  return Matrix(
    rows: IList(
      _$map[r'rows']
          .decodeJsonList<Object?>(context: r'Matrix.rows')
          .map(
            (e) => IList(e.decodeJsonList<String>(context: r'Matrix.rows')),
          )
          .toList(),
    ),
  );
}
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });

      test('toJson unlocks at every nesting level', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = '''
Object? toJson() => {r'rows': rows.unlock.map((e) => e.unlock).toList()};
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });

      test('generates correct nested IList type', () {
        final result = generator.generateClass(model);
        final field = result.fields.firstWhere((f) => f.name == 'rows');
        final typeRef = field.type! as TypeReference;
        expect(typeRef.symbol, 'IList');
        expect(
          typeRef.url,
          'package:fast_immutable_collections/fast_immutable_collections.dart',
        );
        expect(typeRef.types.length, 1);
        final innerRef = typeRef.types.first as TypeReference;
        expect(innerRef.symbol, 'IList');
        expect(innerRef.types.length, 1);
        expect((innerRef.types.first as TypeReference).symbol, 'String');
      });
    });

    group('map with list values (IMap<String, IList<String>>)', () {
      late ClassModel model;

      setUp(() {
        model = ClassModel(
          isDeprecated: false,
          name: 'Lookup',
          properties: [
            Property(
              name: 'data',
              model: MapModel(
                valueModel: ListModel(
                  content: StringModel(context: context),
                  context: context,
                ),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        nameManager.prime(
          models: {model},
          responses: const {},
          requestBodies: const {},
          operations: const {},
          tags: const [],
          servers: const {},
        );
      });

      test('fromJson wraps in IMap and IList at every nesting level', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory Lookup.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'Lookup');
  return Lookup(
    data: IMap(
      _$map[r'data'].decodeJsonMap(
        (v) =>
            IList(v.decodeJsonList<String>(context: r'Lookup.data')),
        context: r'Lookup.data',
      ),
    ),
  );
}
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });

      test('toJson unlocks at every nesting level', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = '''
Object? toJson() => {
  r'data': data.unlock.map((k, v) => MapEntry(k, v.unlock)),
};
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });
    });

    group('backward compatibility', () {
      test('disabled generates regular List and Map fields', () {
        final disabledGenerator = ClassGenerator(
          nameManager: nameManager,
          package: 'example',
        );

        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        nameManager.prime(
          models: {model},
          responses: const {},
          requestBodies: const {},
          operations: const {},
          tags: const [],
          servers: const {},
        );

        final result = disabledGenerator.generateClass(model);
        final field = result.fields.firstWhere((f) => f.name == 'tags');
        final typeRef = field.type! as TypeReference;
        expect(typeRef.symbol, 'List');
        expect(typeRef.url, 'dart:core');
        expect(typeRef.types.length, 1);
        expect((typeRef.types.first as TypeReference).symbol, 'String');
      });

      test('disabled fromJson does not use .lock', () {
        final disabledGenerator = ClassGenerator(
          nameManager: nameManager,
          package: 'example',
        );

        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        nameManager.prime(
          models: {model},
          responses: const {},
          requestBodies: const {},
          operations: const {},
          tags: const [],
          servers: const {},
        );

        final generatedClass = disabledGenerator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory User.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'User');
  return User(
    tags: _$map[r'tags'].decodeJsonList<String>(context: r'User.tags'),
  );
}
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });

      test('disabled toJson returns list directly', () {
        final disabledGenerator = ClassGenerator(
          nameManager: nameManager,
          package: 'example',
        );

        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        nameManager.prime(
          models: {model},
          responses: const {},
          requestBodies: const {},
          operations: const {},
          tags: const [],
          servers: const {},
        );

        final generatedClass = disabledGenerator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = '''
Object? toJson() => {r'tags': tags};
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });
    });

    group('additional properties', () {
      late ClassModel model;

      setUp(() {
        model = ClassModel(
          isDeprecated: false,
          name: 'Flexible',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          additionalProperties: const UnrestrictedAdditionalProperties(),
          context: context,
        );

        nameManager.prime(
          models: {model},
          responses: const {},
          requestBodies: const {},
          operations: const {},
          tags: const [],
          servers: const {},
        );
      });

      test('AP field type is IMap', () {
        final result = generator.generateClass(model);
        final apField = result.fields.firstWhere(
          (f) => f.name == 'additionalProperties',
        );
        final typeRef = apField.type! as TypeReference;
        expect(typeRef.symbol, 'IMap');
        expect(
          typeRef.url,
          'package:fast_immutable_collections/fast_immutable_collections.dart',
        );
        expect(typeRef.types.length, 2);
        expect(typeRef.types.first.symbol, 'String');
      });

      test('constructor default uses IMapConst', () {
        final generatedClass = generator.generateClass(model);
        final ctor = generatedClass.constructors.firstWhere(
          (c) => c.name == null,
        );
        final apParam = ctor.optionalParameters.firstWhere(
          (p) => p.name == 'additionalProperties',
        );
        expect(
          apParam.defaultTo?.accept(emitter).toString(),
          'const IMapConst({})',
        );
      });

      test('fromJson wraps additional properties in IMap constructor', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory Flexible.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'Flexible');
  const _$knownKeys = {r'name'};
  final _$additional = <String, Object?>{};
  for (final _$entry in _$map.entries) {
    if (!_$knownKeys.contains(_$entry.key)) {
      _$additional[_$entry.key] = _$entry.value;
    }
  }
  return Flexible(
    name: _$map[r'name'].decodeJsonString(context: r'Flexible.name'),
    additionalProperties: IMap(_$additional),
  );
}
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });

      test('toJson uses .unlock on additional properties', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = '''
Object? toJson() => {r'name': name, ...additionalProperties.unlock};
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });
    });

    group('fromSimple with collection', () {
      test('fromSimple adds .lock for list property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Tags',
          properties: [
            Property(
              name: 'items',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        nameManager.prime(
          models: {model},
          responses: const {},
          requestBodies: const {},
          operations: const {},
          tags: const [],
          servers: const {},
        );

        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory Tags.fromSimple(String? value, {required bool explode}) {
  final _$values = value.decodeObject(
    explode: explode,
    explodeSeparator: ',',
    expectedKeys: {r'items'},
    listKeys: {r'items'},
    context: r'Tags',
  );
  return Tags(
    items: _$values[r'items']
        .decodeSimpleStringList(context: r'Tags.items')
        .lock,
  );
}
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });
    });

    group('fromForm with collection', () {
      test('fromForm adds .lock for list property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Tags',
          properties: [
            Property(
              name: 'items',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        nameManager.prime(
          models: {model},
          responses: const {},
          requestBodies: const {},
          operations: const {},
          tags: const [],
          servers: const {},
        );

        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory Tags.fromForm(String? value, {required bool explode}) {
  final _$values = value.decodeObject(
    explode: explode,
    explodeSeparator: '&',
    expectedKeys: {r'items'},
    listKeys: {r'items'},
    context: r'Tags',
  );
  return Tags(
    items: _$values[r'items']
        .decodeFormStringList(context: r'Tags.items')
        .lock,
  );
}
''';
        expect(
          collapseWhitespace(code),
          contains(collapseWhitespace(expectedBody)),
        );
      });
    });
  });
}
