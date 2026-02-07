import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late AllOfGenerator generator;
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
    generator = AllOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  /// Builds an AllOf model with schema-level readOnly containing two complex
  /// sub-models.
  AllOfModel buildSchemaReadOnlyModel(Context context) {
    return AllOfModel(
      isDeprecated: false,
      isReadOnly: true,
      name: 'ServerEvent',
      models: {
        ClassModel(
          name: 'BaseEvent',
          isDeprecated: false,
          properties: [
            Property(
              name: 'timestamp',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        ),
        ClassModel(
          name: 'EventMeta',
          isDeprecated: false,
          properties: [
            Property(
              name: 'source',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        ),
      },
      context: context,
    );
  }

  /// Builds an AllOf model with schema-level writeOnly containing two complex
  /// sub-models.
  AllOfModel buildSchemaWriteOnlyModel(Context context) {
    return AllOfModel(
      isDeprecated: false,
      isWriteOnly: true,
      name: 'UserCommand',
      models: {
        ClassModel(
          name: 'CommandBase',
          isDeprecated: false,
          properties: [
            Property(
              name: 'action',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        ),
        ClassModel(
          name: 'CommandPayload',
          isDeprecated: false,
          properties: [
            Property(
              name: 'data',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        ),
      },
      context: context,
    );
  }

  group('schema-level readOnly toJson', () {
    test('toJson throws EncodingException when model has schema-level '
        'readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
        Object? toJson() => throw EncodingException(
          r'ServerEvent is read-only and cannot be encoded.',
        );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level readOnly parameterProperties', () {
    test('parameterProperties throws EncodingException when model is '
        'readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
        }) => throw EncodingException(
          r'ServerEvent is read-only and cannot be encoded.',
        );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level readOnly uriEncode', () {
    test('uriEncode throws EncodingException when model is readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
        String uriEncode({
          required bool allowEmpty,
          bool useQueryComponent = false,
        }) => throw EncodingException(
          r'ServerEvent is read-only and cannot be encoded.',
        );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level readOnly currentEncodingShape', () {
    test('currentEncodingShape throws EncodingException when model is '
        'readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
        EncodingShape get currentEncodingShape => throw EncodingException(
          r'ServerEvent is read-only and cannot be encoded.',
        );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level readOnly constructor and fields', () {
    test('constructor fields are not required when model is readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final combinedClass = generator.generateClass(model);

      final defaultConstructor = combinedClass.constructors.firstWhere(
        (c) => c.name == null,
      );

      for (final param in defaultConstructor.optionalParameters) {
        expect(
          param.required,
          isFalse,
          reason:
              '${param.name} should not be '
              'required in a readOnly model',
        );
      }
    });

    test('field types are nullable when model is readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final combinedClass = generator.generateClass(model);

      for (final field in combinedClass.fields) {
        final typeStr = field.type?.accept(emitter).toString();
        expect(
          typeStr,
          endsWith('?'),
          reason:
              '${field.name} should be '
              'nullable in a readOnly model',
        );
      }
    });
  });

  group('schema-level writeOnly fromJson', () {
    test('fromJson throws JsonDecodingException when model has schema-level '
        'writeOnly', () {
      final model = buildSchemaWriteOnlyModel(context);
      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
        factory UserCommand.fromJson(Object? json) =>
          throw JsonDecodingException(
            r'UserCommand is write-only and cannot be decoded.',
          );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level writeOnly fromSimple', () {
    test('fromSimple throws SimpleDecodingException when model has '
        'schema-level writeOnly', () {
      final model = buildSchemaWriteOnlyModel(context);
      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
        factory UserCommand.fromSimple(String? value, {required bool explode}) =>
          throw SimpleDecodingException(
            r'UserCommand is write-only and cannot be decoded.',
          );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('schema-level writeOnly fromForm', () {
    test('fromForm throws FormDecodingException when model has schema-level '
        'writeOnly', () {
      final model = buildSchemaWriteOnlyModel(context);
      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
        factory UserCommand.fromForm(String? value, {required bool explode}) =>
          throw FormDecodingException(
            r'UserCommand is write-only and cannot be decoded.',
          );
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
