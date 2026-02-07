import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late OneOfGenerator generator;
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
    generator = OneOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  /// Builds a OneOf model with schema-level readOnly containing two complex
  /// variants.
  OneOfModel buildSchemaReadOnlyModel(Context context) {
    return OneOfModel(
      isDeprecated: false,
      isReadOnly: true,
      name: 'ServerEvent',
      models: {
        (
          discriminatorValue: null,
          model: ClassModel(
            name: 'StartEvent',
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
        ),
        (
          discriminatorValue: null,
          model: ClassModel(
            name: 'StopEvent',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reason',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          ),
        ),
      },
      context: context,
    );
  }

  /// Builds a OneOf model with schema-level writeOnly containing two complex
  /// variants.
  OneOfModel buildSchemaWriteOnlyModel(Context context) {
    return OneOfModel(
      isDeprecated: false,
      isWriteOnly: true,
      name: 'UserCommand',
      models: {
        (
          discriminatorValue: null,
          model: ClassModel(
            name: 'CreateUser',
            isDeprecated: false,
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          ),
        ),
        (
          discriminatorValue: null,
          model: ClassModel(
            name: 'DeleteUser',
            isDeprecated: false,
            properties: [
              Property(
                name: 'userId',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          ),
        ),
      },
      context: context,
    );
  }

  group('schema-level readOnly toJson', () {
    test('toJson throws EncodingException when model has schema-level '
        'readOnly', () {
      final model = buildSchemaReadOnlyModel(context);
      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'ServerEvent');
      final classCode = format(baseClass.accept(emitter).toString());

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
      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'ServerEvent');
      final classCode = format(baseClass.accept(emitter).toString());

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
      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'ServerEvent');
      final classCode = format(baseClass.accept(emitter).toString());

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
      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'ServerEvent');
      final classCode = format(baseClass.accept(emitter).toString());

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

  group('schema-level writeOnly fromJson', () {
    test('fromJson throws JsonDecodingException when model has schema-level '
        'writeOnly', () {
      final model = buildSchemaWriteOnlyModel(context);
      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'UserCommand');
      final classCode = format(baseClass.accept(emitter).toString());

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
      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'UserCommand');
      final classCode = format(baseClass.accept(emitter).toString());

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
      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'UserCommand');
      final classCode = format(baseClass.accept(emitter).toString());

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
