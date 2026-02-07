import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late ClassGenerator generator;
  late NameManager nameManager;
  late NameGenerator nameGenerator;
  late Context context;
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    generator = ClassGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  /// Builds a User model with mixed readOnly/writeOnly properties
  /// as they would appear in the raw OpenAPI schema:
  /// - id (integer, readOnly, required)
  /// - name (string, required)
  /// - password (string, writeOnly, required)
  /// - createdAt (string, readOnly, required, nullable)
  ClassModel buildMixedModel(Context context) {
    return ClassModel(
      isDeprecated: false,
      name: 'User',
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
        Property(
          name: 'password',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          isWriteOnly: true,
        ),
        Property(
          name: 'createdAt',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: true,
          isDeprecated: false,
          isReadOnly: true,
        ),
      ],
      context: context,
    );
  }

  group('readOnly/writeOnly toJson', () {
    test('toJson excludes readOnly properties', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        return {r'name': name, r'password': password!};
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toJson throws when required writeOnly is null', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        Object? toJson() {
          if (password == null) {
            throw EncodingException(r'Required property password is null.');
          }
          return {r'name': name, r'password': password!};
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toJson produces empty map when all properties are readOnly', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'ReadOnlyModel',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            isReadOnly: true,
          ),
          Property(
            name: 'createdAt',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            isReadOnly: true,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        Object? toJson() => {};
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('readOnly/writeOnly fromJson', () {
    test('fromJson excludes writeOnly properties', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        factory User.fromJson(Object? json) {
          final map = json.decodeMap(context: r'User');
          return User(
            id: map[r'id'].decodeJsonInt(context: r'User.id'),
            name: map[r'name'].decodeJsonString(context: r'User.name'),
            createdAt: map[r'createdAt'].decodeJsonNullableString(
              context: r'User.createdAt',
            ),
            password: null,
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'fromJson returns empty model when all properties are writeOnly',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'WriteOnlyModel',
          properties: [
            Property(
              name: 'password',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              isWriteOnly: true,
            ),
            Property(
              name: 'secret',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              isWriteOnly: true,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = '''
        factory WriteOnlyModel.fromJson(Object? json) {
          return WriteOnlyModel(password: null, secret: null);
        }
      ''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group('readOnly/writeOnly fromSimple', () {
    test('fromSimple excludes writeOnly properties', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        factory User.fromSimple(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: ',',
            expectedKeys: {r'id', r'name', r'createdAt'},
            listKeys: {},
            context: r'User',
          );
          return User(
            id: values[r'id'].decodeSimpleInt(context: r'User.id'),
            name: values[r'name'].decodeSimpleString(context: r'User.name'),
            createdAt: values[r'createdAt'].decodeSimpleNullableString(
              context: r'User.createdAt',
            ),
            password: null,
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'fromSimple returns empty model when all properties are writeOnly',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'WriteOnlyModel',
          properties: [
            Property(
              name: 'password',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              isWriteOnly: true,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = '''
        factory WriteOnlyModel.fromSimple(String? value, {required bool explode}) {
          return WriteOnlyModel(password: null);
        }
      ''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group('readOnly/writeOnly fromForm', () {
    test('fromForm excludes writeOnly properties', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        factory User.fromForm(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: '&',
            expectedKeys: {r'id', r'name', r'createdAt'},
            listKeys: {},
            context: r'User',
          );
          return User(
            id: values[r'id'].decodeFormInt(context: r'User.id'),
            name: values[r'name'].decodeFormString(context: r'User.name'),
            createdAt: values[r'createdAt'].decodeFormNullableString(
              context: r'User.createdAt',
            ),
            password: null,
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('fromForm returns empty model when all properties are writeOnly', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'WriteOnlyModel',
        properties: [
          Property(
            name: 'password',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            isWriteOnly: true,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        factory WriteOnlyModel.fromForm(String? value, {required bool explode}) {
          return WriteOnlyModel(password: null);
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('readOnly/writeOnly parameterProperties', () {
    test('parameterProperties excludes readOnly properties', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
          bool useQueryComponent = false,
        }) {
          final result = <String, String>{};
          result[r'name'] = name.uriEncode(
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
          );
          if (password == null) {
            throw EncodingException(r'Required property password is null.');
          }
          result[r'password'] = password!.uriEncode(
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
          );
          return result;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('readOnly/writeOnly toSimple', () {
    test('toSimple delegates to filtered parameterProperties', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toSimple(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('readOnly/writeOnly toForm', () {
    test('toForm delegates to filtered parameterProperties', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toForm({
          required bool explode,
          required bool allowEmpty,
          bool useQueryComponent = false,
        }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
          ).toForm(
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('readOnly/writeOnly toLabel', () {
    test('toLabel delegates to filtered parameterProperties', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('readOnly/writeOnly toMatrix', () {
    test('toMatrix delegates to filtered parameterProperties', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return parameterProperties(allowEmpty: allowEmpty).toMatrix(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('readOnly/writeOnly toDeepObject', () {
    test('toDeepObject delegates to filtered parameterProperties', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        List<ParameterEntry> toDeepObject(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowLists: false,
          ).toDeepObject(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('readOnly/writeOnly fields and constructor', () {
    test('all properties are included as fields regardless of '
        'readOnly/writeOnly', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final fieldNames = generatedClass.fields.map((f) => f.name).toList();

      expect(fieldNames, contains('id'));
      expect(fieldNames, contains('name'));
      expect(fieldNames, contains('password'));
      expect(fieldNames, contains('createdAt'));
    });

    test('constructor accepts all properties including readOnly/writeOnly', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final defaultConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == null || c.name!.isEmpty,
      );
      final paramNames = defaultConstructor.optionalParameters
          .map((p) => p.name)
          .toList();

      expect(paramNames, contains('id'));
      expect(paramNames, contains('name'));
      expect(paramNames, contains('password'));
      expect(paramNames, contains('createdAt'));
    });

    test('constructor required flags respect request-only semantics', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final defaultConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == null || c.name!.isEmpty,
      );
      final paramsByName = {
        for (final param in defaultConstructor.optionalParameters)
          param.name: param,
      };

      expect(paramsByName['name']?.required, isTrue);
      expect(paramsByName['password']?.required, isTrue);
      expect(paramsByName['id']?.required, isFalse);
      expect(paramsByName['createdAt']?.required, isFalse);
    });

    test('readOnly required fields are nullable in the model', () {
      final model = buildMixedModel(context);
      final generatedClass = generator.generateClass(model);
      final fieldsByName = {
        for (final field in generatedClass.fields) field.name: field,
      };

      final idType = fieldsByName['id']?.type?.accept(emitter).toString();
      final createdAtType = fieldsByName['createdAt']?.type
          ?.accept(emitter)
          .toString();
      final passwordType = fieldsByName['password']?.type
          ?.accept(emitter)
          .toString();

      expect(idType, equals('int?'));
      expect(createdAtType, equals('String?'));
      expect(passwordType, equals('String?'));
    });
  });

  group('no readOnly/writeOnly properties', () {
    test(
      'all methods include all properties when none are readOnly/writeOnly',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Simple',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'age',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedToJson = '''
        Object? toJson() => {r'name': name, r'age': age};
      ''';

        const expectedFromJson = '''
        factory Simple.fromJson(Object? json) {
          final map = json.decodeMap(context: r'Simple');
          return Simple(
            name: map[r'name'].decodeJsonString(context: r'Simple.name'),
            age: map[r'age'].decodeJsonInt(context: r'Simple.age'),
          );
        }
      ''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedToJson)),
        );
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedFromJson)),
        );
      },
    );
  });
}
