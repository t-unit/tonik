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
        package: 'package:example',
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
        final typeStr = field.type!.accept(emitter).toString();

        expect(typeStr, contains('IList'));
        expect(typeStr, contains('String'));
      });

      test('fromJson uses .lock to convert decoded list', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory User.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'User');
  return User(
    tags: _$map[r'tags'].decodeJsonList<String>(context: r'User.tags').lock,
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
        final typeStr = field.type!.accept(emitter).toString();

        expect(typeStr, contains('IMap'));
        expect(typeStr, contains('String'));
      });

      test('fromJson uses .lock to convert decoded map', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory Config.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'Config');
  return Config(
    settings: _$map[r'settings']
        .decodeJsonMap(
          (v) => v.decodeJsonString(context: r'Config.settings'),
          context: r'Config.settings',
        )
        .lock,
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

      test('fromJson locks at every nesting level', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory Matrix.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'Matrix');
  return Matrix(
    rows: _$map[r'rows']
        .decodeJsonList<Object?>(context: r'Matrix.rows')
        .map((e) => e.decodeJsonList<String>(context: r'Matrix.rows').lock)
        .toList()
        .lock,
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
        final typeStr = field.type!.accept(emitter).toString();

        expect(typeStr, contains('IList'));
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

      test('fromJson locks at every nesting level', () {
        final generatedClass = generator.generateClass(model);
        final code = _formatClass(generatedClass);
        const expectedBody = r'''
factory Lookup.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'Lookup');
  return Lookup(
    data: _$map[r'data']
        .decodeJsonMap(
          (v) =>
              v.decodeJsonList<String>(context: r'Lookup.data').lock,
          context: r'Lookup.data',
        )
        .lock,
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
          package: 'package:example',
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
        final typeStr = field.type!.accept(emitter).toString();

        expect(typeStr, contains('List'));
        expect(typeStr, isNot(contains('IList')));
      });

      test('disabled fromJson does not use .lock', () {
        final disabledGenerator = ClassGenerator(
          nameManager: nameManager,
          package: 'package:example',
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
          package: 'package:example',
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
  });
}
