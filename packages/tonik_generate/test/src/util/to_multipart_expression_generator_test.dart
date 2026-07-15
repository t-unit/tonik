import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/to_multipart_expression_generator.dart';

void main() {
  late NameManager nameManager;
  late Context testContext;
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    testContext = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  /// Wraps a [BuiltStatements] in a method body so it can be
  /// formatted and inspected as a single string.
  String emitStatements(BuiltStatements built) {
    final method = Method(
      (b) => b
        ..name = 'test'
        ..returns = refer('void')
        ..lambda = false
        ..body = Block.of(built.statements),
    );
    return format(method.accept(emitter).toString());
  }

  /// Wraps a [BuiltExpression] in a method body for full-body comparison.
  String emitExpressionAsMethod(BuiltExpression built) {
    expect(built.inlineFunctions, isEmpty);
    final method = Method(
      (b) => b
        ..name = 'test'
        ..returns = refer('void')
        ..lambda = false
        ..body = Block.of([built.unsafeRawBody.statement]),
    );
    return format(method.accept(emitter).toString());
  }

  group('buildMultipartBodyStatements', () {
    test('generates direct field access for required non-nullable string', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'name': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('generates null-check wrapping for required nullable string', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: testContext),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'name': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.name != null) {
              _$formData.files.add(MapEntry(r'name', MultipartFile.fromString(body.name!, contentType: DioMediaType.parse(r'text/plain'))));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('generates null-check wrapping for optional non-nullable string', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'nickname',
            model: StringModel(context: testContext),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'nickname': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.nickname != null) {
              _$formData.files.add(MapEntry(r'nickname', MultipartFile.fromString(body.nickname!, contentType: DioMediaType.parse(r'text/plain'))));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('generates null-check wrapping for optional nullable string', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'bio',
            model: StringModel(context: testContext),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'bio': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.bio != null) {
              _$formData.files.add(MapEntry(r'bio', MultipartFile.fromString(body.bio!, contentType: DioMediaType.parse(r'text/plain'))));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('generates empty FormData for class with zero properties', () {
      final model = ClassModel(
        name: 'EmptyForm',
        isDeprecated: false,
        properties: const [],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: const {},
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('generates UnsupportedError for non-ClassModel body', () {
      final content = RequestContent(
        model: BinaryModel(context: testContext),
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format('''
          void test() {
            throw UnsupportedError(
              'Multipart request bodies require an object schema (ClassModel). Got: BinaryModel.',
            );
          }
        '''),
        ),
      );
    });

    test('resolves AliasModel wrapping non-ClassModel and generates '
        'UnsupportedError', () {
      final content = RequestContent(
        model: AliasModel(
          name: 'BinaryAlias',
          model: BinaryModel(context: testContext),
          context: testContext,
          examples: const [],
          defaultValue: null,
        ),
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format('''
          void test() {
            throw UnsupportedError(
              'Multipart request bodies require an object schema (ClassModel). Got: BinaryModel.',
            );
          }
        '''),
        ),
      );
    });

    test('resolves AliasModel wrapping ClassModel and generates correctly', () {
      final classModel = ClassModel(
        name: 'InnerForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'title',
            model: StringModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: AliasModel(
          name: 'FormAlias',
          model: classModel,
          context: testContext,
          examples: const [],
          defaultValue: null,
        ),
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(classModel, {
          'title': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'title', MultipartFile.fromString(body.title, contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('excludes readOnly properties', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'id',
            model: StringModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            isReadOnly: true,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'name',
            model: StringModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'name': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('includes writeOnly properties', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'password',
            model: StringModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            isWriteOnly: true,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'password': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'password', MultipartFile.fromString(body.password, contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('serializes AnyModel property via jsonEncode()', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'data',
            model: AnyModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'data': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'data', MultipartFile.fromString(jsonEncode(encodeAnyToJson(body.data)), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('generates EncodingException for NeverModel property', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'impossible',
            model: NeverModel(context: testContext, isNullable: false),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'impossible': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            throw EncodingException(
              r"Cannot encode NeverModel property 'impossible' - this type does not permit any value.",
            );
            return _$formData;
          }
        '''),
        ),
      );
    });

    test(
      'NeverModel property name with dollar sign emits raw literal',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: r'$total',
              model: NeverModel(context: testContext, isNullable: false),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            r'$total': const PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              throw EncodingException(
                r"Cannot encode NeverModel property '$total' - this type does not permit any value.",
              );
              return _$formData;
            }
          '''),
          ),
        );
      },
    );
  });

  group('primitive types', () {
    test('serializes IntegerModel with text/plain via toString()', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'age',
            model: IntegerModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'age': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'age', MultipartFile.fromString(body.age.toString(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('serializes DoubleModel with text/plain via toString()', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'score',
            model: DoubleModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'score': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'score', MultipartFile.fromString(body.score.toString(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('serializes NumberModel with text/plain via toString()', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'value',
            model: NumberModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'value': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'value', MultipartFile.fromString(body.value.toString(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('serializes BooleanModel with text/plain via toString()', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'active',
            model: BooleanModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'active': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'active', MultipartFile.fromString(body.active.toString(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('serializes DateModel with text/plain via toString()', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'birth_date',
            model: DateModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'birth_date': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'birth_date', MultipartFile.fromString(body.birthDate.toString(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('serializes DecimalModel with text/plain via toString()', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'amount',
            model: DecimalModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'amount': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'amount', MultipartFile.fromString(body.amount.toString(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('serializes UriModel with text/plain via toString()', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'website',
            model: UriModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'website': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'website', MultipartFile.fromString(body.website.toString(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test(
      'serializes DateTimeModel with text/plain via toTimeZonedIso8601String()',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'created_at',
              model: DateTimeModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'created_at': const PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'created_at', MultipartFile.fromString(body.createdAt.toTimeZonedIso8601String(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'wraps nullable required primitive with text/plain with null-check',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'count',
              model: IntegerModel(context: testContext),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'count': const PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            if (body.count != null) {
              _$formData.files.add(MapEntry(r'count', MultipartFile.fromString(body.count!.toString(), contentType: DioMediaType.parse(r'text/plain'))));
            }
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test('serializes IntegerModel with application/json contentType '
        'via jsonEncode', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'age',
            model: IntegerModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'age': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'age', MultipartFile.fromString(jsonEncode(body.age), contentType: DioMediaType.parse(r'application/json'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('serializes DateTimeModel with application/json contentType '
        'via jsonEncode (not toTimeZonedIso8601String)', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'createdAt',
            model: DateTimeModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'createdAt': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'createdAt', MultipartFile.fromString(jsonEncode(body.createdAt), contentType: DioMediaType.parse(r'application/json'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('serializes BooleanModel with application/json contentType '
        'via jsonEncode', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'active',
            model: BooleanModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'active': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'active', MultipartFile.fromString(jsonEncode(body.active), contentType: DioMediaType.parse(r'application/json'))));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('wraps nullable primitive with null-check when using '
        'application/json contentType', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'score',
            model: IntegerModel(context: testContext),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'score': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.score != null) {
              _$formData.files.add(MapEntry(r'score', MultipartFile.fromString(jsonEncode(body.score!), contentType: DioMediaType.parse(r'application/json'))));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });
  });

  group('style-based encoding with null rawContentType', () {
    test(
      'StringModel falls back to text/plain when rawContentType is null',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'name': const PartEncoding(
              style: EncodingStyle.form,
              explode: true,
              contentType: null,
              rawContentType: null,
              headers: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'IntegerModel falls back to text/plain when rawContentType is null',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'count',
              model: IntegerModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'count': const PartEncoding(
              style: EncodingStyle.form,
              explode: true,
              contentType: null,
              rawContentType: null,
              headers: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'count', MultipartFile.fromString(body.count.toString(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'BooleanModel falls back to text/plain when rawContentType is null',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'active',
              model: BooleanModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'active': const PartEncoding(
              allowReserved: true,
              contentType: null,
              rawContentType: null,
              headers: null,
              style: null,
              explode: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'active', MultipartFile.fromString(body.active.toString(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'DateTimeModel falls back to text/plain when rawContentType is null',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'createdAt',
              model: DateTimeModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'createdAt': const PartEncoding(
              style: EncodingStyle.form,
              explode: false,
              contentType: null,
              rawContentType: null,
              headers: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'createdAt', MultipartFile.fromString(body.createdAt.toTimeZonedIso8601String(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'AnyModel falls back to application/json when rawContentType is null',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'value',
              model: AnyModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'value': const PartEncoding(
              style: EncodingStyle.form,
              explode: true,
              contentType: null,
              rawContentType: null,
              headers: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'value', MultipartFile.fromString(jsonEncode(encodeAnyToJson(body.value)), contentType: DioMediaType.parse(r'application/json'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'EnumModel<String> falls back to text/plain when rawContentType is null',
      () {
        final enumModel = EnumModel<String>(
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: false,
          isDeprecated: false,
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'status',
              model: enumModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'status': const PartEncoding(
              style: EncodingStyle.form,
              explode: true,
              contentType: null,
              rawContentType: null,
              headers: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'status', MultipartFile.fromString(body.status.toJson(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );
  });

  group('enum properties', () {
    test(
      'serializes required EnumModel<String> with text/plain via toJson()',
      () {
        final enumModel = EnumModel<String>(
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: false,
          isDeprecated: false,
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'status',
              model: enumModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'status': const PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'status', MultipartFile.fromString(body.status.toJson(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'serializes required EnumModel<int> with text/plain via toJson().toString()',
      () {
        final enumModel = EnumModel<int>(
          name: 'Count',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
          },
          isNullable: false,
          isDeprecated: false,
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'count',
              model: enumModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'count': const PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'count', MultipartFile.fromString(body.count.toJson().toString(), contentType: DioMediaType.parse(r'text/plain'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'serializes required EnumModel<String> with application/json via toJson()',
      () {
        final enumModel = EnumModel<String>(
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: false,
          isDeprecated: false,
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'status',
              model: enumModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'status': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'status', MultipartFile.fromString(body.status.toJson(), contentType: DioMediaType.parse(r'application/json'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'serializes required EnumModel<int> with application/json via toJson().toString()',
      () {
        final enumModel = EnumModel<int>(
          name: 'Count',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
          },
          isNullable: false,
          isDeprecated: false,
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'count',
              model: enumModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'count': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'count', MultipartFile.fromString(body.count.toJson().toString(), contentType: DioMediaType.parse(r'application/json'))));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test('wraps optional enum with null-check', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        isDeprecated: false,
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'status',
            model: enumModel,
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'status': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.status != null) {
              _$formData.files.add(MapEntry(r'status', MultipartFile.fromString(body.status!.toJson(), contentType: DioMediaType.parse(r'text/plain'))));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('wraps required-but-nullable enum with null-check', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        isDeprecated: false,
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'status',
            model: enumModel,
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'status': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.status != null) {
              _$formData.files.add(MapEntry(r'status', MultipartFile.fromString(body.status!.toJson(), contentType: DioMediaType.parse(r'text/plain'))));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });
  });

  group('binary properties', () {
    test('generates MultipartFile.fromBytes for required binary property', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'avatar',
            model: BinaryModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'avatar': const PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            switch (body.avatar) {
              case TonikFileBytes(:final bytes, :final fileName):
                _$formData.files.add(MapEntry(
                  r'avatar',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? r'avatar'),
                ));
              case TonikFilePath(:final path, :final fileName):
                _$formData.files.add(MapEntry(
                  r'avatar',
                  await MultipartFile.fromFile(path, filename: fileName ?? r'avatar'),
                ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('wraps optional binary property with null-check', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'document',
            model: BinaryModel(context: testContext),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'document': const PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.document != null) {
              switch (body.document!) {
                case TonikFileBytes(:final bytes, :final fileName):
                  _$formData.files.add(MapEntry(
                    r'document',
                    MultipartFile.fromBytes(bytes, filename: fileName ?? r'document'),
                  ));
                case TonikFilePath(:final path, :final fileName):
                  _$formData.files.add(MapEntry(
                    r'document',
                    await MultipartFile.fromFile(path, filename: fileName ?? r'document'),
                  ));
              }
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('wraps required-but-nullable binary property with null-check', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'photo',
            model: BinaryModel(context: testContext),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'photo': const PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.photo != null) {
              switch (body.photo!) {
                case TonikFileBytes(:final bytes, :final fileName):
                  _$formData.files.add(MapEntry(
                    r'photo',
                    MultipartFile.fromBytes(bytes, filename: fileName ?? r'photo'),
                  ));
                case TonikFilePath(:final path, :final fileName):
                  _$formData.files.add(MapEntry(
                    r'photo',
                    await MultipartFile.fromFile(path, filename: fileName ?? r'photo'),
                  ));
              }
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('passes explicit contentType encoding to MultipartFile', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'image',
            model: BinaryModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'image': const PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'image/png',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            switch (body.image) {
              case TonikFileBytes(:final bytes, :final fileName):
                _$formData.files.add(MapEntry(
                  r'image',
                  MultipartFile.fromBytes(
                    bytes,
                    filename: fileName ?? r'image',
                    contentType: DioMediaType.parse(r'image/png'),
                  ),
                ));
              case TonikFilePath(:final path, :final fileName):
                _$formData.files.add(MapEntry(
                  r'image',
                  await MultipartFile.fromFile(
                    path,
                    filename: fileName ?? r'image',
                    contentType: DioMediaType.parse(r'image/png'),
                  ),
                ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('uses default application/octet-stream contentType for binary', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'file',
            model: BinaryModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'file': const PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? r'file'),
                ));
              case TonikFilePath(:final path, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? r'file'),
                ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test(
      'generates binary switch for Base64Model property (same as BinaryModel)',
      () {
        final model = ClassModel(
          name: 'UploadForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'avatar',
              model: Base64Model(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'avatar': const PartEncoding(
              contentType: ContentType.bytes,
              rawContentType: 'application/octet-stream',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            switch (body.avatar) {
              case TonikFileBytes(:final bytes, :final fileName):
                _$formData.files.add(MapEntry(
                  r'avatar',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? r'avatar'),
                ));
              case TonikFilePath(:final path, :final fileName):
                _$formData.files.add(MapEntry(
                  r'avatar',
                  await MultipartFile.fromFile(path, filename: fileName ?? r'avatar'),
                ));
            }
            return _$formData;
          }
        '''),
          ),
        );
      },
    );
  });

  group('complex object properties', () {
    test(
      'generates JSON-encoded file part for required ClassModel property',
      () {
        final innerClass = ClassModel(
          name: 'Address',
          isDeprecated: false,
          properties: [],
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'PersonForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'address',
              model: innerClass,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'address': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: null,
              explode: null,
              allowReserved: null,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(
              r'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse(r'application/json'),
              ),
            ));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test('generates JSON-encoded file part for AllOfModel property', () {
      final allOfModel = AllOfModel(
        name: 'CombinedAddress',
        isDeprecated: false,
        models: {
          StringModel(context: testContext),
        },
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'PersonForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'address',
            model: allOfModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'address': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: null,
            explode: null,
            allowReserved: null,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(
              r'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse(r'application/json'),
              ),
            ));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('generates JSON-encoded file part for OneOfModel property', () {
      final oneOfModel = OneOfModel(
        name: 'AddressVariant',
        isDeprecated: false,
        models: {
          (discriminatorValue: null, model: StringModel(context: testContext)),
        },
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'PersonForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'address',
            model: oneOfModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'address': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: null,
            explode: null,
            allowReserved: null,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(
              r'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse(r'application/json'),
              ),
            ));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('generates JSON-encoded file part for AnyOfModel property', () {
      final anyOfModel = AnyOfModel(
        name: 'AddressMixed',
        isDeprecated: false,
        models: {
          (discriminatorValue: null, model: StringModel(context: testContext)),
        },
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'PersonForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'address',
            model: anyOfModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'address': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: null,
            explode: null,
            allowReserved: null,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(
              r'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse(r'application/json'),
              ),
            ));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('wraps optional complex property with null-check', () {
      final innerClass = ClassModel(
        name: 'Address',
        isDeprecated: false,
        properties: [],
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'PersonForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'address',
            model: innerClass,
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'address': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: null,
            explode: null,
            allowReserved: null,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.address != null) {
              _$formData.files.add(MapEntry(
                r'address',
                MultipartFile.fromString(
                  jsonEncode(body.address!.toJson()),
                  contentType: DioMediaType.parse(r'application/json'),
                ),
              ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('wraps required-but-nullable complex property with null-check', () {
      final innerClass = ClassModel(
        name: 'Address',
        isDeprecated: false,
        properties: [],
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'PersonForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'address',
            model: innerClass,
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'address': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: null,
            explode: null,
            allowReserved: null,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.address != null) {
              _$formData.files.add(MapEntry(
                r'address',
                MultipartFile.fromString(
                  jsonEncode(body.address!.toJson()),
                  contentType: DioMediaType.parse(r'application/json'),
                ),
              ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('uses custom contentType encoding on MultipartFile', () {
      final innerClass = ClassModel(
        name: 'Address',
        isDeprecated: false,
        properties: [],
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'PersonForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'address',
            model: innerClass,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'address': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/xml',
            style: null,
            explode: null,
            allowReserved: null,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(
              r'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse(r'application/xml'),
              ),
            ));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test(
      'generates deepObject-encoded file part for required ClassModel property',
      () {
        final innerClass = ClassModel(
          name: 'Address',
          isDeprecated: false,
          properties: [],
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'PersonForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'address',
              model: innerClass,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'address': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              for (final entry in body.address
                  .toDeepObject(r'address', explode: true, allowEmpty: true)) {
                _$formData.fields.add(MapEntry(entry.name, entry.value));
              }
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates deepObject-encoded file part for optional ClassModel property',
      () {
        final innerClass = ClassModel(
          name: 'Address',
          isDeprecated: false,
          properties: [],
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'PersonForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'address',
              model: innerClass,
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'address': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              if (body.address != null) {
                for (final entry in body.address!
                    .toDeepObject(r'address', explode: true, allowEmpty: true)) {
                  _$formData.fields.add(MapEntry(entry.name, entry.value));
                }
              }
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates deepObject-encoded file part for AllOfModel property',
      () {
        final allOfModel = AllOfModel(
          name: 'CombinedAddress',
          isDeprecated: false,
          models: {
            StringModel(context: testContext),
          },
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'PersonForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'address',
              model: allOfModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'address': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              for (final entry in body.address
                  .toDeepObject(r'address', explode: true, allowEmpty: true)) {
                _$formData.fields.add(MapEntry(entry.name, entry.value));
              }
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates deepObject-encoded file part for OneOfModel property',
      () {
        final oneOfModel = OneOfModel(
          name: 'AddressVariant',
          isDeprecated: false,
          models: {
            (
              discriminatorValue: null,
              model: StringModel(context: testContext),
            ),
          },
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'PersonForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'address',
              model: oneOfModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'address': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              for (final entry in body.address
                  .toDeepObject(r'address', explode: true, allowEmpty: true)) {
                _$formData.fields.add(MapEntry(entry.name, entry.value));
              }
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates deepObject-encoded file part for AnyOfModel property',
      () {
        final anyOfModel = AnyOfModel(
          name: 'AddressMixed',
          isDeprecated: false,
          models: {
            (
              discriminatorValue: null,
              model: StringModel(context: testContext),
            ),
          },
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'PersonForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'address',
              model: anyOfModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'address': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              for (final entry in body.address
                  .toDeepObject(r'address', explode: true, allowEmpty: true)) {
                _$formData.fields.add(MapEntry(entry.name, entry.value));
              }
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test('resolves AliasModel wrapping ClassModel for complex property', () {
      final innerClass = ClassModel(
        name: 'Address',
        isDeprecated: false,
        properties: [],
        context: testContext,
        examples: const [],
      );

      final aliasModel = AliasModel(
        name: 'AddressAlias',
        model: innerClass,
        context: testContext,
        examples: const [],
        defaultValue: null,
      );

      final model = ClassModel(
        name: 'PersonForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'address',
            model: aliasModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'address': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: null,
            explode: null,
            allowReserved: null,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(
              r'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse(r'application/json'),
              ),
            ));
            return _$formData;
          }
        '''),
        ),
      );
    });

    group('content-based mode (URL-encoded)', () {
      test(
        'generates URL-encoded file part for required ClassModel property',
        () {
          final innerClass = ClassModel(
            name: 'Address',
            isDeprecated: false,
            properties: [],
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'PersonForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'address',
                model: innerClass,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'address': const PartEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                final addressEntries = body.address.toForm(
                  r'address',
                  explode: true,
                  allowEmpty: true,
                  useQueryComponent: true,
                );
                _$formData.files.add(MapEntry(
                  r'address',
                  MultipartFile.fromString(
                    addressEntries.map((e) => '${e.name}=${e.value}').join('&'),
                    contentType: DioMediaType.parse(
                      r'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'generates URL-encoded file part for AllOfModel property',
        () {
          final allOfModel = AllOfModel(
            name: 'CombinedAddress',
            isDeprecated: false,
            models: {StringModel(context: testContext)},
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'PersonForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'address',
                model: allOfModel,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'address': const PartEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                final addressEntries = body.address.toForm(
                  r'address',
                  explode: true,
                  allowEmpty: true,
                  useQueryComponent: true,
                );
                _$formData.files.add(MapEntry(
                  r'address',
                  MultipartFile.fromString(
                    addressEntries.map((e) => '${e.name}=${e.value}').join('&'),
                    contentType: DioMediaType.parse(
                      r'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'URL-encoded ClassModel property with single quote in rawName escapes '
        'rawName in the part name literal',
        () {
          final innerClass = ClassModel(
            name: 'PersonName',
            isDeprecated: false,
            properties: [],
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'PersonForm',
            isDeprecated: false,
            properties: [
              Property(
                name: "it's-form",
                model: innerClass,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              "it's-form": const PartEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                final itsFormEntries = body.itsForm.toForm(
                  r"it's-form",
                  explode: true,
                  allowEmpty: true,
                  useQueryComponent: true,
                );
                _$formData.files.add(MapEntry(
                  r"it's-form",
                  MultipartFile.fromString(
                    itsFormEntries.map((e) => '${e.name}=${e.value}').join('&'),
                    contentType: DioMediaType.parse(
                      r'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'URL-encoded ClassModel property with backslash in rawName escapes '
        'rawName in the part name literal',
        () {
          final innerClass = ClassModel(
            name: 'PathTo',
            isDeprecated: false,
            properties: [],
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'PersonForm',
            isDeprecated: false,
            properties: [
              Property(
                name: r'path\form',
                model: innerClass,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              r'path\form': const PartEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                final pathBackslashFormEntries = body.pathBackslashForm.toForm(
                  r'path\form',
                  explode: true,
                  allowEmpty: true,
                  useQueryComponent: true,
                );
                _$formData.files.add(MapEntry(
                  r'path\form',
                  MultipartFile.fromString(
                    pathBackslashFormEntries
                        .map((e) => '${e.name}=${e.value}')
                        .join('&'),
                    contentType: DioMediaType.parse(
                      r'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'URL-encoded ClassModel property with dollar sign in rawName escapes '
        'rawName in the part name literal',
        () {
          final innerClass = ClassModel(
            name: 'DollarForm',
            isDeprecated: false,
            properties: [],
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'PersonForm',
            isDeprecated: false,
            properties: [
              Property(
                name: r'$total',
                model: innerClass,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              r'$total': const PartEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                final $totalEntries = body.$total.toForm(
                  r'$total',
                  explode: true,
                  allowEmpty: true,
                  useQueryComponent: true,
                );
                _$formData.files.add(MapEntry(
                  r'$total',
                  MultipartFile.fromString(
                    $totalEntries.map((e) => '${e.name}=${e.value}').join('&'),
                    contentType: DioMediaType.parse(
                      r'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test('wraps optional URL-encoded property with null-check', () {
        final innerClass = ClassModel(
          name: 'Address',
          isDeprecated: false,
          properties: [],
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'PersonForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'address',
              model: innerClass,
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'address': const PartEncoding(
              contentType: ContentType.form,
              rawContentType: 'application/x-www-form-urlencoded',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              if (body.address != null) {
                final addressEntries = body.address!.toForm(
                  r'address',
                  explode: true,
                  allowEmpty: true,
                  useQueryComponent: true,
                );
                _$formData.files.add(MapEntry(
                  r'address',
                  MultipartFile.fromString(
                    addressEntries.map((e) => '${e.name}=${e.value}').join('&'),
                    contentType: DioMediaType.parse(
                      r'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
              }
              return _$formData;
            }
          '''),
          ),
        );
      });

      test(
        'style-based mode ignores contentType and emits raw style parts',
        () {
          final innerClass = ClassModel(
            name: 'Address',
            isDeprecated: false,
            properties: [],
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'PersonForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'address',
                model: innerClass,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'address': const PartEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                // style/explode present → style-based mode, contentType ignored
                style: EncodingStyle.form,
                explode: true,
                allowReserved: false,
                headers: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                final addressRawParts = body.address
                    .parameterProperties(allowEmpty: true)
                    .toRawStyleParts(r'address', explode: true);
                for (final _$part in addressRawParts) {
                  _$formData.files.add(
                    MapEntry(_$part.name, MultipartFile.fromString(_$part.value)),
                  );
                }
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'style-based raw parts pass per-part headers to every part',
        () {
          final innerClass = ClassModel(
            name: 'Address',
            isDeprecated: false,
            properties: [],
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'PersonForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'address',
                model: innerClass,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'address': PartEncoding(
                contentType: null,
                rawContentType: null,
                style: EncodingStyle.form,
                explode: true,
                allowReserved: null,
                headers: {
                  'X-Custom-Header': ResponseHeaderObject(
                    name: 'X-Custom-Header',
                    description: null,
                    isRequired: true,
                    isDeprecated: false,
                    explode: false,
                    model: StringModel(context: testContext),
                    context: testContext,
                    encoding: ResponseHeaderEncoding.simple,
                    examples: const [],
                  ),
                },
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                final _$addressHeaders = <String, List<String>>{};
                _$addressHeaders[r'X-Custom-Header'] = [
                  addressCustomHeader.toSimple(explode: false, allowEmpty: true),
                ];
                final addressRawParts = body.address
                    .parameterProperties(allowEmpty: true)
                    .toRawStyleParts(r'address', explode: true);
                for (final _$part in addressRawParts) {
                  _$formData.files.add(
                    MapEntry(
                      _$part.name,
                      MultipartFile.fromString(
                        _$part.value,
                        headers: _$addressHeaders,
                      ),
                    ),
                  );
                }
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'non-form styled object parts throw instead of rendering with '
        'form semantics',
        () {
          final innerClass = ClassModel(
            name: 'Address',
            isDeprecated: false,
            properties: [],
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'PersonForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'address',
                model: innerClass,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'address': const PartEncoding(
                contentType: null,
                rawContentType: null,
                style: EncodingStyle.pipeDelimited,
                explode: true,
                allowReserved: null,
                headers: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                throw EncodingException(
                  r'pipeDelimited style is not supported for object multipart part address',
                );
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'non-exploded style-based mode emits one raw comma-joined part',
        () {
          final innerClass = ClassModel(
            name: 'Address',
            isDeprecated: false,
            properties: [],
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'PersonForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'address',
                model: innerClass,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'address': const PartEncoding(
                contentType: null,
                rawContentType: null,
                style: EncodingStyle.form,
                explode: false,
                allowReserved: null,
                headers: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                final addressRawParts = body.address
                    .parameterProperties(allowEmpty: true)
                    .toRawStyleParts(r'address', explode: false);
                for (final _$part in addressRawParts) {
                  _$formData.files.add(
                    MapEntry(_$part.name, MultipartFile.fromString(_$part.value)),
                  );
                }
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'URL-encoded property with per-part headers passes headers to '
        'MultipartFile',
        () {
          final innerClass = ClassModel(
            name: 'Address',
            isDeprecated: false,
            properties: [],
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'PersonForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'address',
                model: innerClass,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'address': PartEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                headers: {
                  'X-Custom-Header': ResponseHeaderObject(
                    name: 'X-Custom-Header',
                    description: null,
                    isRequired: true,
                    isDeprecated: false,
                    explode: false,
                    model: StringModel(context: testContext),
                    context: testContext,
                    encoding: ResponseHeaderEncoding.simple,
                    examples: const [],
                  ),
                },
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                final _$addressHeaders = <String, List<String>>{};
                _$addressHeaders[r'X-Custom-Header'] = [
                  addressCustomHeader.toSimple(explode: false, allowEmpty: true),
                ];
                final addressEntries = body.address.toForm(
                  r'address',
                  explode: true,
                  allowEmpty: true,
                  useQueryComponent: true,
                );
                _$formData.files.add(MapEntry(
                  r'address',
                  MultipartFile.fromString(
                    addressEntries.map((e) => '${e.name}=${e.value}').join('&'),
                    contentType: DioMediaType.parse(
                      r'application/x-www-form-urlencoded',
                    ),
                    headers: _$addressHeaders,
                  ),
                ));
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test('colliding per-part header names use their distinct parameters', () {
        final model = ClassModel(
          name: 'UploadForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'file',
              model: BinaryModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );
        final headers = {
          for (final rawName in ['X-Trace-Id', 'Trace-Id'])
            rawName: ResponseHeaderObject(
              name: rawName,
              description: null,
              isRequired: true,
              isDeprecated: false,
              explode: false,
              model: StringModel(context: testContext),
              context: testContext,
              encoding: ResponseHeaderEncoding.simple,
              examples: const [],
            ),
        };
        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'file': PartEncoding(
              contentType: ContentType.bytes,
              rawContentType: 'application/octet-stream',
              headers: headers,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final code = emitStatements(
          buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          ),
        );

        expect(
          collapseWhitespace(code),
          contains(
            collapseWhitespace(
              'fileTraceIdPartHeader.toSimple('
              'explode: false, allowEmpty: true)',
            ),
          ),
        );
      });
    });
  });

  group('MapModel properties', () {
    test(
      'generates JSON-encoded file part for required MapModel property',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'metadata',
              model: mapModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'metadata': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              _$formData.files.add(MapEntry(
                r'metadata',
                MultipartFile.fromString(
                  jsonEncode(body.metadata),
                  contentType: DioMediaType.parse(r'application/json'),
                ),
              ));
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates JSON-encoded file part for optional MapModel property',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'metadata',
              model: mapModel,
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'metadata': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              if (body.metadata != null) {
                _$formData.files.add(MapEntry(
                  r'metadata',
                  MultipartFile.fromString(
                    jsonEncode(body.metadata!),
                    contentType: DioMediaType.parse(r'application/json'),
                  ),
                ));
              }
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates JSON-encoded file part for MapModel with default encoding',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'metadata',
              model: mapModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              _$formData.files.add(MapEntry(
                r'metadata',
                MultipartFile.fromString(
                  jsonEncode(body.metadata),
                  contentType: DioMediaType.parse(r'application/json'),
                ),
              ));
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates deepObject error for MapModel property',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'metadata',
              model: mapModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'metadata': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              throw EncodingException(
                r'deepObject style is not supported for map multipart properties (property: metadata). Maps do not implement ParameterEncodable.toDeepObject().',
              );
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'deepObject error for MapModel uses raw literal when property name '
      'has special characters',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: "it's-meta",
              model: mapModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            "it's-meta": const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              throw EncodingException(
                r"deepObject style is not supported for map multipart properties (property: it's-meta). Maps do not implement ParameterEncodable.toDeepObject().",
              );
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates URL-encoded file part for required MapModel property',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'metadata',
              model: mapModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'metadata': const PartEncoding(
              contentType: ContentType.form,
              rawContentType: 'application/x-www-form-urlencoded',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              final metadataParts = <String>[];
              for (final entry in ((body.metadata as Map)).entries) {
                final value = entry.value;
                if (value == null) continue;
                if (value is Map || value is List) {
                  throw EncodingException(
                    'Standard URL encoding does not support nested values (property: ' r'metadata' ', key: ${entry.key}). Only flat key=value pairs are allowed.',
                  );
                }
                metadataParts.add(
                  [
                    Uri.encodeQueryComponent(entry.key.toString()),
                    Uri.encodeQueryComponent(value.toString()),
                  ].join('='),
                );
              }
              _$formData.files.add(MapEntry(
                r'metadata',
                MultipartFile.fromString(
                  metadataParts.join('&'),
                  contentType: DioMediaType.parse(
                    r'application/x-www-form-urlencoded',
                  ),
                ),
              ));
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates URL-encoded file part for optional MapModel property',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'metadata',
              model: mapModel,
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'metadata': const PartEncoding(
              contentType: ContentType.form,
              rawContentType: 'application/x-www-form-urlencoded',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              if (body.metadata != null) {
                final metadataParts = <String>[];
                for (final entry in ((body.metadata! as Map)).entries) {
                  final value = entry.value;
                  if (value == null) continue;
                  if (value is Map || value is List) {
                    throw EncodingException(
                      'Standard URL encoding does not support nested values (property: ' r'metadata' ', key: ${entry.key}). Only flat key=value pairs are allowed.',
                    );
                  }
                  metadataParts.add(
                    [
                      Uri.encodeQueryComponent(entry.key.toString()),
                      Uri.encodeQueryComponent(value.toString()),
                    ].join('='),
                  );
                }
                _$formData.files.add(MapEntry(
                  r'metadata',
                  MultipartFile.fromString(
                    metadataParts.join('&'),
                    contentType: DioMediaType.parse(
                      r'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
              }
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'URL-encoded MapModel property with single quote in rawName escapes '
      'rawName in the EncodingException literal',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: "it's-meta",
              model: mapModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            "it's-meta": const PartEncoding(
              contentType: ContentType.form,
              rawContentType: 'application/x-www-form-urlencoded',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              final itsMetaParts = <String>[];
              for (final entry in ((body.itsMeta as Map)).entries) {
                final value = entry.value;
                if (value == null) continue;
                if (value is Map || value is List) {
                  throw EncodingException(
                    'Standard URL encoding does not support nested values (property: ' r"it's-meta" ', key: ${entry.key}). Only flat key=value pairs are allowed.',
                  );
                }
                itsMetaParts.add(
                  [
                    Uri.encodeQueryComponent(entry.key.toString()),
                    Uri.encodeQueryComponent(value.toString()),
                  ].join('='),
                );
              }
              _$formData.files.add(MapEntry(
                r"it's-meta",
                MultipartFile.fromString(
                  itsMetaParts.join('&'),
                  contentType: DioMediaType.parse(
                    r'application/x-www-form-urlencoded',
                  ),
                ),
              ));
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'URL-encoded MapModel property with backslash in rawName escapes '
      'rawName in the EncodingException literal',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: r'path\to',
              model: mapModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            r'path\to': const PartEncoding(
              contentType: ContentType.form,
              rawContentType: 'application/x-www-form-urlencoded',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              final pathBackslashToParts = <String>[];
              for (final entry in ((body.pathBackslashTo as Map)).entries) {
                final value = entry.value;
                if (value == null) continue;
                if (value is Map || value is List) {
                  throw EncodingException(
                    'Standard URL encoding does not support nested values (property: ' r'path\to' ', key: ${entry.key}). Only flat key=value pairs are allowed.',
                  );
                }
                pathBackslashToParts.add(
                  [
                    Uri.encodeQueryComponent(entry.key.toString()),
                    Uri.encodeQueryComponent(value.toString()),
                  ].join('='),
                );
              }
              _$formData.files.add(MapEntry(
                r'path\to',
                MultipartFile.fromString(
                  pathBackslashToParts.join('&'),
                  contentType: DioMediaType.parse(
                    r'application/x-www-form-urlencoded',
                  ),
                ),
              ));
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'URL-encoded MapModel property with dollar sign in rawName escapes '
      'rawName in the EncodingException literal',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: r'$total',
              model: mapModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            r'$total': const PartEncoding(
              contentType: ContentType.form,
              rawContentType: 'application/x-www-form-urlencoded',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              final $totalParts = <String>[];
              for (final entry in ((body.$total as Map)).entries) {
                final value = entry.value;
                if (value == null) continue;
                if (value is Map || value is List) {
                  throw EncodingException(
                    'Standard URL encoding does not support nested values (property: ' r'$total' ', key: ${entry.key}). Only flat key=value pairs are allowed.',
                  );
                }
                $totalParts.add(
                  [
                    Uri.encodeQueryComponent(entry.key.toString()),
                    Uri.encodeQueryComponent(value.toString()),
                  ].join('='),
                );
              }
              _$formData.files.add(MapEntry(
                r'$total',
                MultipartFile.fromString(
                  $totalParts.join('&'),
                  contentType: DioMediaType.parse(
                    r'application/x-www-form-urlencoded',
                  ),
                ),
              ));
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates JSON-encoded file part for MapModel through alias',
      () {
        final mapModel = MapModel(
          valueModel: StringModel(context: testContext),
          context: testContext,
          examples: const [],
        );

        final aliasModel = AliasModel(
          name: 'MetadataAlias',
          model: mapModel,
          context: testContext,
          examples: const [],
          defaultValue: null,
        );

        final model = ClassModel(
          name: 'ResourceForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'metadata',
              model: aliasModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'metadata': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              _$formData.files.add(MapEntry(
                r'metadata',
                MultipartFile.fromString(
                  jsonEncode(body.metadata),
                  contentType: DioMediaType.parse(r'application/json'),
                ),
              ));
              return _$formData;
            }
          '''),
          ),
        );
      },
    );
  });

  group('array properties', () {
    // --- Style / explode tests (text/plain contentType) ---

    test('list of strings, explode: true, style: form', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'tags': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.tags) {
              _$formData.fields.add(MapEntry(r'tags', item));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of strings, explode: true, style: spaceDelimited', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'tags': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.spaceDelimited,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.tags) {
              _$formData.fields.add(MapEntry(r'tags', item));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of strings, explode: false, style: form', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'tags': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: false,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.fields.add(MapEntry(r'tags', body.tags.uriEncode(allowEmpty: true, alreadyEncoded: true)));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of strings, explode: false, style: spaceDelimited', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'tags': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.spaceDelimited,
            explode: false,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.tags.toSpaceDelimited(explode: false, allowEmpty: true, alreadyEncoded: true, percentEncodeDelimiter: false)) {
              _$formData.fields.add(MapEntry(r'tags', item));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of strings, explode: false, style: pipeDelimited', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'tags': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.pipeDelimited,
            explode: false,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.tags.toPipeDelimited(explode: false, allowEmpty: true, alreadyEncoded: true)) {
              _$formData.fields.add(MapEntry(r'tags', item));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of strings, explode: false, style: deepObject '
        'generates runtime error', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'tags': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.deepObject,
            explode: false,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            throw EncodingException(
              r'deepObject style is not supported for array multipart properties (property: tags).',
            );
            return _$formData;
          }
        '''),
        ),
      );
    });

    test(
      'deepObject error for list uses raw literal when property name '
      'has special characters',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: "it's-tags",
              model: ListModel(
                content: StringModel(context: testContext),
                context: testContext,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            "it's-tags": const PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: EncodingStyle.deepObject,
              explode: false,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              throw EncodingException(
                r"deepObject style is not supported for array multipart properties (property: it's-tags).",
              );
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    // --- Enum tests ---

    test('list of string enums, explode: true', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        isDeprecated: false,
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'statuses',
            model: ListModel(
              content: enumModel,
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'statuses': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.statuses) {
              _$formData.fields.add(MapEntry(r'statuses', item.uriEncode(allowEmpty: true)));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of int enums, explode: false, style: form', () {
      final enumModel = EnumModel<int>(
        name: 'Code',
        values: {
          const EnumEntry(value: 1),
          const EnumEntry(value: 2),
        },
        isNullable: false,
        isDeprecated: false,
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'codes',
            model: ListModel(
              content: enumModel,
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'codes': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: false,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.fields.add(MapEntry(r'codes', body.codes.map((item) => item.uriEncode(allowEmpty: true)).toList().uriEncode(allowEmpty: true, alreadyEncoded: true)));
            return _$formData;
          }
        '''),
        ),
      );
    });

    // --- ContentType tests ---

    test('list of integers, text/plain, explode: true', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'scores',
            model: ListModel(
              content: IntegerModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'scores': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.scores) {
              _$formData.fields.add(MapEntry(r'scores', item.toString()));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of integers, application/json, explode: true', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'scores',
            model: ListModel(
              content: IntegerModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'scores': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.scores) {
              _$formData.fields.add(MapEntry(r'scores', jsonEncode(item)));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of integers, application/json, explode: false', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'scores',
            model: ListModel(
              content: IntegerModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'scores': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: EncodingStyle.form,
            explode: false,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            _$formData.fields.add(MapEntry(r'scores', body.scores.map((item) => jsonEncode(item)).toList().uriEncode(allowEmpty: true, alreadyEncoded: true)));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of DateTimeModel, text/plain, explode: true', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'dates',
            model: ListModel(
              content: DateTimeModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'dates': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.dates) {
              _$formData.fields.add(MapEntry(r'dates', item.toTimeZonedIso8601String()));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of DateTimeModel, application/json, explode: true', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'dates',
            model: ListModel(
              content: DateTimeModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'dates': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.dates) {
              _$formData.fields.add(MapEntry(r'dates', jsonEncode(item)));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    // --- Binary tests ---

    test('list of binary, explode: true', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'files',
            model: ListModel(
              content: BinaryModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'files': const PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.files) {
              switch (item) {
                case TonikFileBytes(:final bytes, :final fileName):
                  _$formData.files.add(MapEntry(r'files', MultipartFile.fromBytes(bytes, filename: fileName ?? r'files')));
                case TonikFilePath(:final path, :final fileName):
                  _$formData.files.add(MapEntry(r'files', await MultipartFile.fromFile(path, filename: fileName ?? r'files')));
              }
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of binary, explode: false (treated as exploded)', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'files',
            model: ListModel(
              content: BinaryModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'files': const PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: EncodingStyle.form,
            explode: false,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.files) {
              switch (item) {
                case TonikFileBytes(:final bytes, :final fileName):
                  _$formData.files.add(MapEntry(r'files', MultipartFile.fromBytes(bytes, filename: fileName ?? r'files')));
                case TonikFilePath(:final path, :final fileName):
                  _$formData.files.add(MapEntry(r'files', await MultipartFile.fromFile(path, filename: fileName ?? r'files')));
              }
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    // --- Complex object tests ---

    test('list of ClassModel, explode: true', () {
      final innerClass = ClassModel(
        name: 'Address',
        isDeprecated: false,
        properties: [],
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'addresses',
            model: ListModel(
              content: innerClass,
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'addresses': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.addresses) {
              _$formData.files.add(MapEntry(r'addresses', MultipartFile.fromString(jsonEncode(item.toJson()), contentType: DioMediaType.parse(r'application/json'))));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('list of ClassModel, custom contentType', () {
      final innerClass = ClassModel(
        name: 'Address',
        isDeprecated: false,
        properties: [],
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'addresses',
            model: ListModel(
              content: innerClass,
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'addresses': const PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/xml',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            for (final item in body.addresses) {
              _$formData.files.add(MapEntry(r'addresses', MultipartFile.fromString(jsonEncode(item.toJson()), contentType: DioMediaType.parse(r'application/xml'))));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    // --- Nullable / optional tests ---

    test('optional list property wraps in null-check', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'tags': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.tags != null) {
              for (final item in body.tags!) {
                _$formData.fields.add(MapEntry(r'tags', item));
              }
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('required-but-nullable list wraps in null-check', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'tags': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.tags != null) {
              for (final item in body.tags!) {
                _$formData.fields.add(MapEntry(r'tags', item));
              }
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    group('content-based mode (no style fields)', () {
      test('list of strings, application/json, content-based mode', () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: testContext),
                context: testContext,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'tags': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              _$formData.files.add(MapEntry(r'tags', MultipartFile.fromString(jsonEncode(body.tags), contentType: DioMediaType.parse(r'application/json'))));
              return _$formData;
            }
          '''),
          ),
        );
      });

      test('list of integers, application/json, content-based mode', () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'scores',
              model: ListModel(
                content: IntegerModel(context: testContext),
                context: testContext,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'scores': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              _$formData.files.add(MapEntry(r'scores', MultipartFile.fromString(jsonEncode(body.scores), contentType: DioMediaType.parse(r'application/json'))));
              return _$formData;
            }
          '''),
          ),
        );
      });

      test(
        'list of strings, no encoding at all → repeated text/plain fields',
        () {
          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'tags',
                model: ListModel(
                  content: StringModel(context: testContext),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
            void test() {
              final _$formData = FormData();
              for (final item in body.tags) {
                _$formData.fields.add(MapEntry(r'tags', item));
              }
              return _$formData;
            }
          '''),
            ),
          );
        },
      );

      test('list of ClassModel, content-based mode', () {
        final innerClass = ClassModel(
          name: 'Address',
          isDeprecated: false,
          properties: [],
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'addresses',
              model: ListModel(
                content: innerClass,
                context: testContext,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'addresses': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              _$formData.files.add(MapEntry(r'addresses', MultipartFile.fromString(jsonEncode(body.addresses.map((e) => e.toJson()).toList()), contentType: DioMediaType.parse(r'application/json'))));
              return _$formData;
            }
          '''),
          ),
        );
      });

      test('list of DateTimeModel, content-based mode', () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'dates',
              model: ListModel(
                content: DateTimeModel(context: testContext),
                context: testContext,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'dates': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              _$formData.files.add(MapEntry(r'dates', MultipartFile.fromString(jsonEncode(body.dates.map((e) => e.toTimeZonedIso8601String()).toList()), contentType: DioMediaType.parse(r'application/json'))));
              return _$formData;
            }
          '''),
          ),
        );
      });

      test('optional list, content-based mode, null-wrapping applies', () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: testContext),
                context: testContext,
                examples: const [],
              ),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'tags': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              if (body.tags != null) {
                _$formData.files.add(MapEntry(r'tags', MultipartFile.fromString(jsonEncode(body.tags!), contentType: DioMediaType.parse(r'application/json'))));
              }
              return _$formData;
            }
          '''),
          ),
        );
      });

      test(
        'list of strings, text/plain contentType (parser default) '
        '→ repeated text/plain fields',
        () {
          // In OAS 3.0/3.1 the parser computes contentType: text/plain as the
          // default for string/scalar array items. With no style fields set,
          // the default is repeated parts (one per element), not a JSON blob.
          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'tags',
                model: ListModel(
                  content: StringModel(context: testContext),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'tags': const PartEncoding(
                contentType: ContentType.text,
                rawContentType: 'text/plain',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                for (final item in body.tags) {
                  _$formData.fields.add(MapEntry(r'tags', item));
                }
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'list of integers, text/plain (parser default) → repeated form fields',
        () {
          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'scores',
                model: ListModel(
                  content: IntegerModel(context: testContext),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'scores': const PartEncoding(
                contentType: ContentType.text,
                rawContentType: 'text/plain',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                for (final item in body.scores) {
                  _$formData.fields.add(MapEntry(r'scores', item.toString()));
                }
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'list of DateTimes, text/plain (parser default) → repeated ISO 8601 fields',
        () {
          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'dates',
                model: ListModel(
                  content: DateTimeModel(context: testContext),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'dates': const PartEncoding(
                contentType: ContentType.text,
                rawContentType: 'text/plain',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                for (final item in body.dates) {
                  _$formData.fields.add(MapEntry(r'dates', item.toTimeZonedIso8601String()));
                }
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'list of enums, text/plain (parser default) → repeated uriEncode fields',
        () {
          final enumModel = EnumModel<String>(
            name: 'Priority',
            isNullable: false,
            isDeprecated: false,
            values: {
              const EnumEntry(value: 'high'),
              const EnumEntry(value: 'low'),
            },
            context: testContext,
            examples: const [],
          );

          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'priorities',
                model: ListModel(
                  content: enumModel,
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'priorities': const PartEncoding(
                contentType: ContentType.text,
                rawContentType: 'text/plain',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                for (final item in body.priorities) {
                  _$formData.fields.add(MapEntry(r'priorities', item.uriEncode(allowEmpty: true)));
                }
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'optional list, no encoding → repeated fields with null guard',
        () {
          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'tags',
                model: ListModel(
                  content: StringModel(context: testContext),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                if (body.tags != null) {
                  for (final item in body.tags!) {
                    _$formData.fields.add(MapEntry(r'tags', item));
                  }
                }
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test('list of string enums, content-based mode → JSON-encoded array', () {
        final enumModel = EnumModel<String>(
          name: 'Priority',
          isNullable: false,
          isDeprecated: false,
          values: {
            const EnumEntry(value: 'high'),
            const EnumEntry(value: 'low'),
          },
          context: testContext,
          examples: const [],
        );

        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'priorities',
              model: ListModel(
                content: enumModel,
                context: testContext,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'priorities': const PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              headers: null,
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              _$formData.files.add(MapEntry(r'priorities', MultipartFile.fromString(jsonEncode(body.priorities.map((e) => e.toJson()).toList()), contentType: DioMediaType.parse(r'application/json'))));
              return _$formData;
            }
          '''),
          ),
        );
      });

      test(
        'list of BinaryModel, content-based mode (no style) → '
        'binary for-loop per item',
        () {
          // BinaryModel items bypass the content-based/style-based check and
          // always produce a for-loop, matching the plan's "one file part per
          // binary item" rule.
          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'files',
                model: ListModel(
                  content: BinaryModel(context: testContext),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'files': const PartEncoding(
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                for (final item in body.files) {
                  switch (item) {
                    case TonikFileBytes(:final bytes, :final fileName):
                      _$formData.files.add(MapEntry(r'files', MultipartFile.fromBytes(bytes, filename: fileName ?? r'files')));
                    case TonikFilePath(:final path, :final fileName):
                      _$formData.files.add(MapEntry(r'files', await MultipartFile.fromFile(path, filename: fileName ?? r'files')));
                  }
                }
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'list of ListModel items (array-of-arrays), '
        'content-based mode → EncodingException',
        () {
          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'matrix',
                model: ListModel(
                  content: ListModel(
                    content: IntegerModel(context: testContext),
                    context: testContext,
                    examples: const [],
                  ),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'matrix': const PartEncoding(
                contentType: ContentType.json,
                rawContentType: 'application/json',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                throw EncodingException(
                  r'Arrays of arrays are not supported for multipart encoding (property: matrix).',
                );
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'arrays-of-arrays error uses raw literal when property name '
        'has special characters',
        () {
          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: r'$matrix',
                model: ListModel(
                  content: ListModel(
                    content: IntegerModel(context: testContext),
                    context: testContext,
                    examples: const [],
                  ),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              r'$matrix': const PartEncoding(
                contentType: ContentType.json,
                rawContentType: 'application/json',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                throw EncodingException(
                  r'Arrays of arrays are not supported for multipart encoding (property: $matrix).',
                );
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'list with explicit unsupported contentType, '
        'content-based mode → EncodingException',
        () {
          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: StringModel(context: testContext),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              'items': const PartEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                throw EncodingException(
                  r'Unsupported contentType "application/x-www-form-urlencoded" for array multipart property "items". Only application/json is supported for content-based array serialization.',
                );
                return _$formData;
              }
            '''),
            ),
          );
        },
      );

      test(
        'unsupported contentType error uses raw literal when property name '
        'has special characters',
        () {
          final model = ClassModel(
            name: 'TestForm',
            isDeprecated: false,
            properties: [
              Property(
                name: "it's-items",
                model: ListModel(
                  content: StringModel(context: testContext),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            multipartEncoding: _multipartEncoding(model, {
              "it's-items": const PartEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            }),
            examples: const [],
          );

          final result = buildMultipartBodyStatements(
            content,
            'body',
            nameManager,
            'test_package',
          );

          final code = emitStatements(result);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                final _$formData = FormData();
                throw EncodingException(
                  r"""Unsupported contentType "application/x-www-form-urlencoded" for array multipart property "it's-items". Only application/json is supported for content-based array serialization.""",
                );
                return _$formData;
              }
            '''),
            ),
          );
        },
      );
    });
  });

  group('buildMultipartBodyExpression', () {
    test('returns IIFE for ClassModel with string property', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'name': const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyExpression(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitExpressionAsMethod(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            await () async {
              final _$formData = FormData();
              _$formData.files.add(MapEntry(r'name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse(r'text/plain'))));
              return _$formData;
            }();
          }
        '''),
        ),
      );
    });

    test('returns IIFE with UnsupportedError for non-ClassModel', () {
      final content = RequestContent(
        model: BinaryModel(context: testContext),
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        examples: const [],
      );

      final result = buildMultipartBodyExpression(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitExpressionAsMethod(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format('''
          void test() {
            await () async {
              throw UnsupportedError(
                'Multipart request bodies require an object schema (ClassModel). Got: BinaryModel.',
              );
            }();
          }
        '''),
        ),
      );
    });
  });

  group('per-part headers', () {
    test('binary property with one required header passes headers to '
        'MultipartFile', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'file',
            model: BinaryModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'file': PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: EncodingStyle.form,
            explode: true,
            allowReserved: false,
            headers: {
              'X-Rate-Limit': ResponseHeaderObject(
                name: 'X-Rate-Limit',
                context: testContext,
                description: null,
                explode: false,
                model: IntegerModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$fileHeaders = <String, List<String>>{};
            _$fileHeaders[r'X-Rate-Limit'] = [fileRateLimit.toSimple(explode: false, allowEmpty: true)];
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? r'file', headers: _$fileHeaders),
                ));
              case TonikFilePath(:final path, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? r'file', headers: _$fileHeaders),
                ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('binary property with optional header wraps in null check', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'file',
            model: BinaryModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'file': PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            headers: {
              'X-Tag': ResponseHeaderObject(
                name: 'X-Tag',
                context: testContext,
                description: null,
                explode: false,
                model: StringModel(context: testContext),
                isRequired: false,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            style: null,
            explode: null,
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$fileHeaders = <String, List<String>>{};
            if (fileTag != null) {
              _$fileHeaders[r'X-Tag'] = [fileTag.toSimple(explode: false, allowEmpty: true)];
            }
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? r'file', headers: _$fileHeaders),
                ));
              case TonikFilePath(:final path, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? r'file', headers: _$fileHeaders),
                ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('complex object with headers passes headers to MultipartFile', () {
      final innerClass = ClassModel(
        name: 'Address',
        isDeprecated: false,
        properties: [],
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'PersonForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'address',
            model: innerClass,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'address': PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            headers: {
              'X-Custom': ResponseHeaderObject(
                name: 'X-Custom',
                context: testContext,
                description: null,
                explode: false,
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            style: null,
            explode: null,
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$addressHeaders = <String, List<String>>{};
            _$addressHeaders[r'X-Custom'] = [addressCustom.toSimple(explode: false, allowEmpty: true)];
            _$formData.files.add(MapEntry(
              r'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse(r'application/json'),
                headers: _$addressHeaders,
              ),
            ));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('string field with headers converts to MultipartFile.fromString', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'description',
            model: StringModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'description': PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            headers: {
              'X-Language': ResponseHeaderObject(
                name: 'X-Language',
                context: testContext,
                description: null,
                explode: false,
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            style: null,
            explode: null,
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$descriptionHeaders = <String, List<String>>{};
            _$descriptionHeaders[r'X-Language'] = [descriptionLanguage.toSimple(explode: false, allowEmpty: true)];
            _$formData.files.add(MapEntry(
              r'description',
              MultipartFile.fromString(body.description, contentType: DioMediaType.parse(r'text/plain'), headers: _$descriptionHeaders),
            ));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test(
      'primitive field with headers converts to MultipartFile.fromString',
      () {
        final model = ClassModel(
          name: 'UploadForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'count',
              model: IntegerModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'count': PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              headers: {
                'X-Source': ResponseHeaderObject(
                  name: 'X-Source',
                  context: testContext,
                  description: null,
                  explode: false,
                  model: StringModel(context: testContext),
                  isRequired: true,
                  isDeprecated: false,
                  encoding: ResponseHeaderEncoding.simple,
                  examples: const [],
                ),
              },
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            final _$countHeaders = <String, List<String>>{};
            _$countHeaders[r'X-Source'] = [countSource.toSimple(explode: false, allowEmpty: true)];
            _$formData.files.add(MapEntry(
              r'count',
              MultipartFile.fromString(body.count.toString(), contentType: DioMediaType.parse(r'text/plain'), headers: _$countHeaders),
            ));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test('enum field with headers converts to MultipartFile.fromString', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        isDeprecated: false,
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'status',
            model: enumModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'status': PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            headers: {
              'X-Custom': ResponseHeaderObject(
                name: 'X-Custom',
                context: testContext,
                description: null,
                explode: false,
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            style: null,
            explode: null,
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$statusHeaders = <String, List<String>>{};
            _$statusHeaders[r'X-Custom'] = [statusCustom.toSimple(explode: false, allowEmpty: true)];
            _$formData.files.add(MapEntry(
              r'status',
              MultipartFile.fromString(body.status.toJson(), contentType: DioMediaType.parse(r'text/plain'), headers: _$statusHeaders),
            ));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('Content-Type header is filtered out from per-part headers', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'file',
            model: BinaryModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'file': PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            headers: {
              'Content-Type': ResponseHeaderObject(
                name: 'Content-Type',
                context: testContext,
                description: null,
                explode: false,
                model: StringModel(context: testContext),
                isRequired: false,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            style: null,
            explode: null,
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      // No headers map since only Content-Type was present and it's filtered.
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? r'file'),
                ));
              case TonikFilePath(:final path, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? r'file'),
                ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('multiple headers on one property are all included', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'file',
            model: BinaryModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'file': PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            headers: {
              'X-Rate-Limit': ResponseHeaderObject(
                name: 'X-Rate-Limit',
                context: testContext,
                description: null,
                explode: false,
                model: IntegerModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
              'X-Tag': ResponseHeaderObject(
                name: 'X-Tag',
                context: testContext,
                description: null,
                explode: false,
                model: StringModel(context: testContext),
                isRequired: false,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            style: null,
            explode: null,
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$fileHeaders = <String, List<String>>{};
            _$fileHeaders[r'X-Rate-Limit'] = [fileRateLimit.toSimple(explode: false, allowEmpty: true)];
            if (fileTag != null) {
              _$fileHeaders[r'X-Tag'] = [fileTag.toSimple(explode: false, allowEmpty: true)];
            }
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? r'file', headers: _$fileHeaders),
                ));
              case TonikFilePath(:final path, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? r'file', headers: _$fileHeaders),
                ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('property without headers does not generate headers map', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'file',
            model: BinaryModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'file': const PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            headers: null,
            style: null,
            explode: null,
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? r'file'),
                ));
              case TonikFilePath(:final path, :final fileName):
                _$formData.files.add(MapEntry(
                  r'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? r'file'),
                ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('exploded string list with headers uses MultipartFile.fromString '
        'per item', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'tags': PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: true,
            headers: {
              'X-Custom': ResponseHeaderObject(
                name: 'X-Custom',
                context: testContext,
                description: null,
                explode: false,
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$tagsHeaders = <String, List<String>>{};
            _$tagsHeaders[r'X-Custom'] = [tagsCustom.toSimple(explode: false, allowEmpty: true)];
            for (final item in body.tags) {
              _$formData.files.add(MapEntry(r'tags', MultipartFile.fromString(item, headers: _$tagsHeaders)));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('non-exploded string list with headers uses MultipartFile.fromString '
        'for encoded value', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'tags': PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: EncodingStyle.form,
            explode: false,
            headers: {
              'X-Custom': ResponseHeaderObject(
                name: 'X-Custom',
                context: testContext,
                description: null,
                explode: false,
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$tagsHeaders = <String, List<String>>{};
            _$tagsHeaders[r'X-Custom'] = [tagsCustom.toSimple(explode: false, allowEmpty: true)];
            _$formData.files.add(MapEntry(r'tags', MultipartFile.fromString(body.tags.uriEncode(allowEmpty: true, alreadyEncoded: true), headers: _$tagsHeaders)));
            return _$formData;
          }
        '''),
        ),
      );
    });

    test(
      'non-exploded space-delimited string list with headers wraps the '
      'encoded value in MultipartFile.fromString',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: testContext),
                context: testContext,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'tags': PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: EncodingStyle.spaceDelimited,
              explode: false,
              headers: {
                'X-Custom': ResponseHeaderObject(
                  name: 'X-Custom',
                  context: testContext,
                  description: null,
                  explode: false,
                  model: StringModel(context: testContext),
                  isRequired: true,
                  isDeprecated: false,
                  encoding: ResponseHeaderEncoding.simple,
                  examples: const [],
                ),
              },
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            final _$tagsHeaders = <String, List<String>>{};
            _$tagsHeaders[r'X-Custom'] = [tagsCustom.toSimple(explode: false, allowEmpty: true)];
            for (final item in body.tags.toSpaceDelimited(explode: false, allowEmpty: true, alreadyEncoded: true, percentEncodeDelimiter: false)) {
              _$formData.files.add(MapEntry(r'tags', MultipartFile.fromString(item, headers: _$tagsHeaders)));
            }
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'non-exploded pipe-delimited DateTime list with headers maps items and '
      'wraps the encoded value in MultipartFile.fromString',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'dates',
              model: ListModel(
                content: DateTimeModel(context: testContext),
                context: testContext,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'dates': PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: EncodingStyle.pipeDelimited,
              explode: false,
              headers: {
                'X-Custom': ResponseHeaderObject(
                  name: 'X-Custom',
                  context: testContext,
                  description: null,
                  explode: false,
                  model: StringModel(context: testContext),
                  isRequired: true,
                  isDeprecated: false,
                  encoding: ResponseHeaderEncoding.simple,
                  examples: const [],
                ),
              },
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            final _$datesHeaders = <String, List<String>>{};
            _$datesHeaders[r'X-Custom'] = [datesCustom.toSimple(explode: false, allowEmpty: true)];
            for (final item in body.dates.map((item) => item.toTimeZonedIso8601String()).toList().toPipeDelimited(explode: false, allowEmpty: true, alreadyEncoded: true)) {
              _$formData.files.add(MapEntry(r'dates', MultipartFile.fromString(item, headers: _$datesHeaders)));
            }
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test('exploded binary list with headers passes headers to '
        'MultipartFile.fromBytes', () {
      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'files',
            model: ListModel(
              content: BinaryModel(context: testContext),
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'files': PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: EncodingStyle.form,
            explode: true,
            headers: {
              'X-Checksum': ResponseHeaderObject(
                name: 'X-Checksum',
                context: testContext,
                description: null,
                explode: false,
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$filesHeaders = <String, List<String>>{};
            _$filesHeaders[r'X-Checksum'] = [filesChecksum.toSimple(explode: false, allowEmpty: true)];
            for (final item in body.files) {
              switch (item) {
                case TonikFileBytes(:final bytes, :final fileName):
                  _$formData.files.add(MapEntry(r'files', MultipartFile.fromBytes(bytes, filename: fileName ?? r'files', headers: _$filesHeaders)));
                case TonikFilePath(:final path, :final fileName):
                  _$formData.files.add(MapEntry(r'files', await MultipartFile.fromFile(path, filename: fileName ?? r'files', headers: _$filesHeaders)));
              }
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('exploded complex list with headers passes headers to '
        'MultipartFile.fromString', () {
      final innerClass = ClassModel(
        name: 'Address',
        isDeprecated: false,
        properties: [],
        context: testContext,
        examples: const [],
      );

      final model = ClassModel(
        name: 'TestForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'addresses',
            model: ListModel(
              content: innerClass,
              context: testContext,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'addresses': PartEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: EncodingStyle.form,
            explode: true,
            headers: {
              'X-Custom': ResponseHeaderObject(
                name: 'X-Custom',
                context: testContext,
                description: null,
                explode: false,
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$addressesHeaders = <String, List<String>>{};
            _$addressesHeaders[r'X-Custom'] = [addressesCustom.toSimple(explode: false, allowEmpty: true)];
            for (final item in body.addresses) {
              _$formData.files.add(MapEntry(r'addresses', MultipartFile.fromString(jsonEncode(item.toJson()), contentType: DioMediaType.parse(r'application/json'), headers: _$addressesHeaders)));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test('required header on optional property uses null assertion', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'file',
            model: BinaryModel(context: testContext),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'file': PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            headers: {
              'X-Rate-Limit': ResponseHeaderObject(
                name: 'X-Rate-Limit',
                context: testContext,
                description: null,
                explode: false,
                model: IntegerModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
            style: null,
            explode: null,
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      // The header param is nullable because the property is optional,
      // but the header is required — so it needs ! when accessed.
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            if (body.file != null) {
              final _$fileHeaders = <String, List<String>>{};
              _$fileHeaders[r'X-Rate-Limit'] = [fileRateLimit!.toSimple(explode: false, allowEmpty: true)];
              switch (body.file!) {
                case TonikFileBytes(:final bytes, :final fileName):
                  _$formData.files.add(MapEntry(
                    r'file',
                    MultipartFile.fromBytes(bytes, filename: fileName ?? r'file', headers: _$fileHeaders),
                  ));
                case TonikFilePath(:final path, :final fileName):
                  _$formData.files.add(MapEntry(
                    r'file',
                    await MultipartFile.fromFile(path, filename: fileName ?? r'file', headers: _$fileHeaders),
                  ));
              }
            }
            return _$formData;
          }
        '''),
        ),
      );
    });

    test(
      'required header on nullable required property uses null assertion',
      () {
        final model = ClassModel(
          name: 'UploadForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'file',
              model: BinaryModel(context: testContext),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'file': PartEncoding(
              contentType: ContentType.bytes,
              rawContentType: 'application/octet-stream',
              headers: {
                'X-Checksum': ResponseHeaderObject(
                  name: 'X-Checksum',
                  context: testContext,
                  description: null,
                  explode: false,
                  model: StringModel(context: testContext),
                  isRequired: true,
                  isDeprecated: false,
                  encoding: ResponseHeaderEncoding.simple,
                  examples: const [],
                ),
              },
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            if (body.file != null) {
              final _$fileHeaders = <String, List<String>>{};
              _$fileHeaders[r'X-Checksum'] = [fileChecksum!.toSimple(explode: false, allowEmpty: true)];
              switch (body.file!) {
                case TonikFileBytes(:final bytes, :final fileName):
                  _$formData.files.add(MapEntry(
                    r'file',
                    MultipartFile.fromBytes(bytes, filename: fileName ?? r'file', headers: _$fileHeaders),
                  ));
                case TonikFilePath(:final path, :final fileName):
                  _$formData.files.add(MapEntry(
                    r'file',
                    await MultipartFile.fromFile(path, filename: fileName ?? r'file', headers: _$fileHeaders),
                  ));
              }
            }
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'AnyModel field with headers converts to MultipartFile.fromString',
      () {
        final model = ClassModel(
          name: 'UploadForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'data',
              model: AnyModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'data': PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              headers: {
                'X-Custom': ResponseHeaderObject(
                  name: 'X-Custom',
                  context: testContext,
                  description: null,
                  explode: false,
                  model: StringModel(context: testContext),
                  isRequired: true,
                  isDeprecated: false,
                  encoding: ResponseHeaderEncoding.simple,
                  examples: const [],
                ),
              },
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            final _$dataHeaders = <String, List<String>>{};
            _$dataHeaders[r'X-Custom'] = [dataCustom.toSimple(explode: false, allowEmpty: true)];
            _$formData.files.add(MapEntry(
              r'data',
              MultipartFile.fromString(jsonEncode(encodeAnyToJson(body.data)), contentType: DioMediaType.parse(r'text/plain'), headers: _$dataHeaders),
            ));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'primitive field with json contentType and headers uses jsonEncode in '
      'MultipartFile.fromString',
      () {
        final model = ClassModel(
          name: 'UploadForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'count',
              model: IntegerModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'count': PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              headers: {
                'X-Source': ResponseHeaderObject(
                  name: 'X-Source',
                  context: testContext,
                  description: null,
                  explode: false,
                  model: StringModel(context: testContext),
                  isRequired: true,
                  isDeprecated: false,
                  encoding: ResponseHeaderEncoding.simple,
                  examples: const [],
                ),
              },
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            final _$countHeaders = <String, List<String>>{};
            _$countHeaders[r'X-Source'] = [countSource.toSimple(explode: false, allowEmpty: true)];
            _$formData.files.add(MapEntry(
              r'count',
              MultipartFile.fromString(jsonEncode(body.count), contentType: DioMediaType.parse(r'application/json'), headers: _$countHeaders),
            ));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'DateTimeModel field with json contentType and headers uses jsonEncode '
      'in MultipartFile.fromString',
      () {
        final model = ClassModel(
          name: 'UploadForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'createdAt',
              model: DateTimeModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'createdAt': PartEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              headers: {
                'X-Source': ResponseHeaderObject(
                  name: 'X-Source',
                  context: testContext,
                  description: null,
                  explode: false,
                  model: StringModel(context: testContext),
                  isRequired: true,
                  isDeprecated: false,
                  encoding: ResponseHeaderEncoding.simple,
                  examples: const [],
                ),
              },
              style: null,
              explode: null,
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            final _$createdAtHeaders = <String, List<String>>{};
            _$createdAtHeaders[r'X-Source'] = [createdAtSource.toSimple(explode: false, allowEmpty: true)];
            _$formData.files.add(MapEntry(
              r'createdAt',
              MultipartFile.fromString(jsonEncode(body.createdAt), contentType: DioMediaType.parse(r'application/json'), headers: _$createdAtHeaders),
            ));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test(
      'non-exploded DateTime list with headers sends one mapped encoded part',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'dates',
              model: ListModel(
                content: DateTimeModel(context: testContext),
                context: testContext,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'dates': PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: EncodingStyle.form,
              explode: false,
              headers: {
                'X-Custom': ResponseHeaderObject(
                  name: 'X-Custom',
                  context: testContext,
                  description: null,
                  explode: false,
                  model: StringModel(context: testContext),
                  isRequired: true,
                  isDeprecated: false,
                  encoding: ResponseHeaderEncoding.simple,
                  examples: const [],
                ),
              },
              allowReserved: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
          void test() {
            final _$formData = FormData();
            final _$datesHeaders = <String, List<String>>{};
            _$datesHeaders[r'X-Custom'] = [datesCustom.toSimple(explode: false, allowEmpty: true)];
            _$formData.files.add(MapEntry(r'dates', MultipartFile.fromString(body.dates.map((item) => item.toTimeZonedIso8601String()).toList().uriEncode(allowEmpty: true, alreadyEncoded: true), headers: _$datesHeaders)));
            return _$formData;
          }
        '''),
          ),
        );
      },
    );

    test('resolves ResponseHeaderAlias to underlying header object', () {
      final model = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
        properties: [
          Property(
            name: 'document',
            model: BinaryModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: testContext,
        examples: const [],
      );

      // Create a header alias that wraps a real header object.
      final underlyingHeader = ResponseHeaderObject(
        name: 'X-Trace-Id',
        context: testContext,
        description: 'Trace identifier',
        explode: false,
        model: StringModel(context: testContext),
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
        examples: const [],
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        multipartEncoding: _multipartEncoding(model, {
          'document': PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            headers: {
              'X-Trace-Id': ResponseHeaderAlias(
                name: 'X-Trace-Id',
                context: testContext,
                header: underlyingHeader,
              ),
            },
            style: null,
            explode: null,
            allowReserved: null,
          ),
        }),
        examples: const [],
      );

      final result = buildMultipartBodyStatements(
        content,
        'body',
        nameManager,
        'test_package',
      );

      final code = emitStatements(result);
      // Alias should resolve transparently — same output as direct header.
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          format(r'''
          void test() {
            final _$formData = FormData();
            final _$documentHeaders = <String, List<String>>{};
            _$documentHeaders[r'X-Trace-Id'] = [documentTraceId.toSimple(explode: false, allowEmpty: true)];
            switch (body.document) {
              case TonikFileBytes(:final bytes, :final fileName):
                _$formData.files.add(MapEntry(
                  r'document',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? r'document', headers: _$documentHeaders),
                ));
              case TonikFilePath(:final path, :final fileName):
                _$formData.files.add(MapEntry(
                  r'document',
                  await MultipartFile.fromFile(path, filename: fileName ?? r'document', headers: _$documentHeaders),
                ));
            }
            return _$formData;
          }
        '''),
        ),
      );
    });
  });

  group('special characters in multipart field names and content types', () {
    test(
      'generates valid code when rawContentType contains single quote',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            'name': const PartEncoding(
              contentType: ContentType.text,
              rawContentType: "text/it's-plain",
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              _$formData.files.add(MapEntry(r'name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse(r"text/it's-plain"))));
              return _$formData;
            }
          '''),
          ),
        );
      },
    );

    test(
      'generates valid code when field name contains single quote',
      () {
        final model = ClassModel(
          name: 'TestForm',
          isDeprecated: false,
          properties: [
            Property(
              name: "it's-field",
              model: BinaryModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          multipartEncoding: _multipartEncoding(model, {
            "it's-field": const PartEncoding(
              contentType: ContentType.bytes,
              rawContentType: 'application/octet-stream',
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
              headers: null,
            ),
          }),
          examples: const [],
        );

        final result = buildMultipartBodyStatements(
          content,
          'body',
          nameManager,
          'test_package',
        );

        final code = emitStatements(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
            void test() {
              final _$formData = FormData();
              switch (body.itsField) {
                case TonikFileBytes(:final bytes, :final fileName):
                  _$formData.files.add(MapEntry(
                    r"it's-field",
                    MultipartFile.fromBytes(bytes, filename: fileName ?? r"it's-field"),
                  ));
                case TonikFilePath(:final path, :final fileName):
                  _$formData.files.add(MapEntry(
                    r"it's-field",
                    await MultipartFile.fromFile(path, filename: fileName ?? r"it's-field"),
                  ));
              }
              return _$formData;
            }
          '''),
          ),
        );
      },
    );
  });
}

Map<Property, PartEncoding> _multipartEncoding(
  ClassModel model,
  Map<String, PartEncoding> byName,
) {
  return {
    for (final entry in byName.entries)
      model.properties.firstWhere((p) => p.name == entry.key): entry.value,
  };
}
