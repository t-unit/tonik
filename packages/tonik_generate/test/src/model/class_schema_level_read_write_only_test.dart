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

  /// Builds a model with schema-level readOnly.
  ClassModel buildSchemaReadOnlyModel(Context context) {
    return ClassModel(
      isDeprecated: false,
      isReadOnly: true,
      name: 'ServerStatus',
      properties: [
        Property(
          name: 'uptime',
          model: IntegerModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
        Property(
          name: 'version',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
        Property(
          name: 'region',
          model: StringModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
        ),
      ],
      context: context,
    );
  }

  /// Builds a model with schema-level writeOnly.
  ClassModel buildSchemaWriteOnlyModel(Context context) {
    return ClassModel(
      isDeprecated: false,
      isWriteOnly: true,
      name: 'PasswordReset',
      properties: [
        Property(
          name: 'newPassword',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
        Property(
          name: 'confirmPassword',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
        Property(
          name: 'hint',
          model: StringModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
        ),
      ],
      context: context,
    );
  }

  group('schema-level readOnly toJson', () {
    test('toJson throws EncodingException when model has schema-level '
        'readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      // A readOnly schema must never be serialized for a request.
      const expectedMethod = '''
        Object? toJson() => throw EncodingException(
          r'ServerStatus is read-only and cannot be encoded.',
        );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level readOnly fromJson', () {
    test('fromJson decodes all properties when model has schema-level '
        'readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      // All properties should be decoded normally.
      const expectedMethod = '''
        factory ServerStatus.fromJson(Object? json) {
          final map = json.decodeMap(context: r'ServerStatus');
          return ServerStatus(
            uptime: map[r'uptime'].decodeJsonInt(context: r'ServerStatus.uptime'),
            version: map[r'version'].decodeJsonString(
              context: r'ServerStatus.version',
            ),
            region: map[r'region'].decodeJsonNullableString(
              context: r'ServerStatus.region',
            ),
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level readOnly constructor', () {
    test(
      'constructor makes all properties optional when model is readOnly',
      () {
        final model = buildSchemaReadOnlyModel(context);
        final generatedClass = generator.generateClass(model);
        final defaultConstructor = generatedClass.constructors.firstWhere(
          (c) => c.name == null || c.name!.isEmpty,
        );
        final paramsByName = {
          for (final param in defaultConstructor.optionalParameters)
            param.name: param,
        };

        // All properties should be optional because the schema is readOnly.
        expect(paramsByName['uptime']?.required, isFalse);
        expect(paramsByName['version']?.required, isFalse);
        expect(paramsByName['region']?.required, isFalse);
      },
    );
  });

  group('schema-level readOnly fields', () {
    test('all fields are nullable when model is readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final generatedClass = generator.generateClass(model);
      final fieldsByName = {
        for (final field in generatedClass.fields) field.name: field,
      };

      final uptimeType = fieldsByName['uptime']?.type
          ?.accept(emitter)
          .toString();
      final versionType = fieldsByName['version']?.type
          ?.accept(emitter)
          .toString();
      final regionType = fieldsByName['region']?.type
          ?.accept(emitter)
          .toString();

      expect(uptimeType, equals('int?'));
      expect(versionType, equals('String?'));
      expect(regionType, equals('String?'));
    });
  });

  group('schema-level readOnly parameterProperties', () {
    test('parameterProperties throws EncodingException when model is '
        'readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
          bool useQueryComponent = false,
        }) => throw EncodingException(
          r'ServerStatus is read-only and cannot be encoded.',
        );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level writeOnly toJson', () {
    test('toJson includes all properties when model has schema-level '
        'writeOnly', () {
      final model = buildSchemaWriteOnlyModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      // All properties should be serialized because the schema is writeOnly
      // (sent to server).
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace("r'newPassword': newPassword")),
      );
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace("r'confirmPassword': confirmPassword")),
      );
    });
  });

  group('schema-level writeOnly fromJson', () {
    test('fromJson throws JsonDecodingException when model has schema-level '
        'writeOnly', () {
      final model = buildSchemaWriteOnlyModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      // A writeOnly schema must never be deserialized from a response.
      const expectedMethod = '''
        factory PasswordReset.fromJson(Object? json) => throw JsonDecodingException(
          r'PasswordReset is write-only and cannot be decoded.',
        );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level writeOnly constructor', () {
    test('constructor keeps required properties when model is writeOnly', () {
      final model = buildSchemaWriteOnlyModel(context);
      final generatedClass = generator.generateClass(model);
      final defaultConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == null || c.name!.isEmpty,
      );
      final paramsByName = {
        for (final param in defaultConstructor.optionalParameters)
          param.name: param,
      };

      // Required properties stay required for writeOnly schemas.
      expect(paramsByName['newPassword']?.required, isTrue);
      expect(paramsByName['confirmPassword']?.required, isTrue);
      expect(paramsByName['hint']?.required, isFalse);
    });
  });

  group('schema-level writeOnly fields', () {
    test('fields retain their normal nullability when model is writeOnly', () {
      final model = buildSchemaWriteOnlyModel(context);
      final generatedClass = generator.generateClass(model);
      final fieldsByName = {
        for (final field in generatedClass.fields) field.name: field,
      };

      final newPasswordType = fieldsByName['newPassword']?.type
          ?.accept(emitter)
          .toString();
      final confirmPasswordType = fieldsByName['confirmPassword']?.type
          ?.accept(emitter)
          .toString();
      final hintType = fieldsByName['hint']?.type?.accept(emitter).toString();

      // writeOnly schemas are sent to server; fields keep normal types.
      expect(newPasswordType, equals('String'));
      expect(confirmPasswordType, equals('String'));
      expect(hintType, equals('String?'));
    });
  });

  group('schema-level writeOnly fromSimple', () {
    test('fromSimple throws SimpleDecodingException when model has '
        'schema-level writeOnly', () {
      final model = buildSchemaWriteOnlyModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        factory PasswordReset.fromSimple(String? value, {required bool explode}) =>
          throw SimpleDecodingException(
            r'PasswordReset is write-only and cannot be decoded.',
          );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level writeOnly fromForm', () {
    test('fromForm throws FormatDecodingException when model has schema-level '
        'writeOnly', () {
      final model = buildSchemaWriteOnlyModel(context);
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        factory PasswordReset.fromForm(String? value, {required bool explode}) =>
          throw FormatDecodingException(
            r'PasswordReset is write-only and cannot be decoded.',
          );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level readOnly combined with property-level writeOnly', () {
    test('toJson throws because schema is readOnly', () {
      final model = ClassModel(
        isDeprecated: false,
        isReadOnly: true,
        name: 'Mixed',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
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
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      // Schema-level readOnly trumps everything: encoding is never valid.
      expect(
        collapseWhitespace(classCode),
        contains(
          collapseWhitespace(
            '''Object? toJson() => throw EncodingException(r'Mixed is read-only and cannot be encoded.');''',
          ),
        ),
      );
    });
  });
}
