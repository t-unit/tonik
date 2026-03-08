import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/to_multipart_expression_generator.dart';

void main() {
  late NameManager nameManager;
  late Context testContext;
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameManager = NameManager(generator: NameGenerator());
    testContext = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  /// Wraps a list of [Code] statements in a method body so they can be
  /// formatted and inspected as a single string.
  String emitStatements(List<Code> statements) {
    final method = Method(
      (b) => b
        ..name = 'test'
        ..returns = refer('void')
        ..lambda = false
        ..body = Block.of(statements),
    );
    return format(method.accept(emitter).toString());
  }

  /// Wraps an [Expression] in a method body for full-body comparison.
  String emitExpressionAsMethod(Expression expr) {
    final method = Method(
      (b) => b
        ..name = 'test'
        ..returns = refer('void')
        ..lambda = false
        ..body = Block.of([expr.statement]),
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'name': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse('text/plain'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'name': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.name != null) {
              formData.files.add(MapEntry('name', MultipartFile.fromString(body.name!, contentType: DioMediaType.parse('text/plain'))));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'nickname': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.nickname != null) {
              formData.files.add(MapEntry('nickname', MultipartFile.fromString(body.nickname!, contentType: DioMediaType.parse('text/plain'))));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'bio': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.bio != null) {
              formData.files.add(MapEntry('bio', MultipartFile.fromString(body.bio!, contentType: DioMediaType.parse('text/plain'))));
            }
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
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: const {},
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
            final formData = FormData();
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
        ),
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: AliasModel(
          name: 'FormAlias',
          model: classModel,
          context: testContext,
        ),
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'title': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('title', MultipartFile.fromString(body.title, contentType: DioMediaType.parse('text/plain'))));
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
          ),
          Property(
            name: 'name',
            model: StringModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'name': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse('text/plain'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'password': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('password', MultipartFile.fromString(body.password, contentType: DioMediaType.parse('text/plain'))));
          }
        '''),
        ),
      );
    });

    test('serializes AnyModel property via toString()', () {
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'data': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('data', MultipartFile.fromString(body.data.toString(), contentType: DioMediaType.parse('text/plain'))));
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
            model: NeverModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'impossible': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            throw EncodingException(
              'Cannot encode NeverModel property \'impossible\' - this type does not permit any value.',
            );
          }
        '''),
        ),
      );
    });
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'age': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('age', MultipartFile.fromString(body.age.toString(), contentType: DioMediaType.parse('text/plain'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'score': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('score', MultipartFile.fromString(body.score.toString(), contentType: DioMediaType.parse('text/plain'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'value': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('value', MultipartFile.fromString(body.value.toString(), contentType: DioMediaType.parse('text/plain'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'active': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('active', MultipartFile.fromString(body.active.toString(), contentType: DioMediaType.parse('text/plain'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'birth_date': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('birth_date', MultipartFile.fromString(body.birthDate.toString(), contentType: DioMediaType.parse('text/plain'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'amount': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('amount', MultipartFile.fromString(body.amount.toString(), contentType: DioMediaType.parse('text/plain'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'website': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('website', MultipartFile.fromString(body.website.toString(), contentType: DioMediaType.parse('text/plain'))));
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'created_at': const MultipartPropertyEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: MultipartEncodingStyle.form,
              explode: true,
              allowReserved: false,
            ),
          },
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
            final formData = FormData();
            formData.files.add(MapEntry('created_at', MultipartFile.fromString(body.createdAt.toTimeZonedIso8601String(), contentType: DioMediaType.parse('text/plain'))));
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'count': const MultipartPropertyEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: MultipartEncodingStyle.form,
              explode: true,
              allowReserved: false,
            ),
          },
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
            final formData = FormData();
            if (body.count != null) {
              formData.files.add(MapEntry('count', MultipartFile.fromString(body.count!.toString(), contentType: DioMediaType.parse('text/plain'))));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'age': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('age', MultipartFile.fromString(jsonEncode(body.age), contentType: DioMediaType.parse('application/json'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'createdAt': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('createdAt', MultipartFile.fromString(jsonEncode(body.createdAt), contentType: DioMediaType.parse('application/json'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'active': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('active', MultipartFile.fromString(jsonEncode(body.active), contentType: DioMediaType.parse('application/json'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'score': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.score != null) {
              formData.files.add(MapEntry('score', MultipartFile.fromString(jsonEncode(body.score!), contentType: DioMediaType.parse('application/json'))));
            }
          }
        '''),
        ),
      );
    });
  });

  group('style-based encoding with null rawContentType', () {
    test('StringModel falls back to text/plain when rawContentType is null', () {
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'name': const MultipartPropertyEncoding(
            style: MultipartEncodingStyle.form,
            explode: true,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse('text/plain'))));
          }
        '''),
        ),
      );
    });

    test('IntegerModel falls back to text/plain when rawContentType is null', () {
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'count': const MultipartPropertyEncoding(
            style: MultipartEncodingStyle.form,
            explode: true,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('count', MultipartFile.fromString(body.count.toString(), contentType: DioMediaType.parse('text/plain'))));
          }
        '''),
        ),
      );
    });

    test('BooleanModel falls back to text/plain when rawContentType is null', () {
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'active': const MultipartPropertyEncoding(
            allowReserved: true,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('active', MultipartFile.fromString(body.active.toString(), contentType: DioMediaType.parse('text/plain'))));
          }
        '''),
        ),
      );
    });

    test('DateTimeModel falls back to text/plain when rawContentType is null', () {
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'createdAt': const MultipartPropertyEncoding(
            style: MultipartEncodingStyle.form,
            explode: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('createdAt', MultipartFile.fromString(body.createdAt.toTimeZonedIso8601String(), contentType: DioMediaType.parse('text/plain'))));
          }
        '''),
        ),
      );
    });

    test('AnyModel falls back to text/plain when rawContentType is null', () {
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'value': const MultipartPropertyEncoding(
            style: MultipartEncodingStyle.form,
            explode: true,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('value', MultipartFile.fromString(body.value.toString(), contentType: DioMediaType.parse('text/plain'))));
          }
        '''),
        ),
      );
    });

    test('EnumModel<String> falls back to text/plain when rawContentType is null', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        isDeprecated: false,
        context: testContext,
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'status': const MultipartPropertyEncoding(
            style: MultipartEncodingStyle.form,
            explode: true,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry('status', MultipartFile.fromString(body.status.toJson(), contentType: DioMediaType.parse('text/plain'))));
          }
        '''),
        ),
      );
    });
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'status': const MultipartPropertyEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: MultipartEncodingStyle.form,
              explode: true,
              allowReserved: false,
            ),
          },
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
            final formData = FormData();
            formData.files.add(MapEntry('status', MultipartFile.fromString(body.status.toJson(), contentType: DioMediaType.parse('text/plain'))));
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'count': const MultipartPropertyEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: MultipartEncodingStyle.form,
              explode: true,
              allowReserved: false,
            ),
          },
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
            final formData = FormData();
            formData.files.add(MapEntry('count', MultipartFile.fromString(body.count.toJson().toString(), contentType: DioMediaType.parse('text/plain'))));
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'status': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: MultipartEncodingStyle.form,
              explode: true,
              allowReserved: false,
            ),
          },
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
            final formData = FormData();
            formData.files.add(MapEntry('status', MultipartFile.fromString(body.status.toJson(), contentType: DioMediaType.parse('application/json'))));
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'count': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: MultipartEncodingStyle.form,
              explode: true,
              allowReserved: false,
            ),
          },
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
            final formData = FormData();
            formData.files.add(MapEntry('count', MultipartFile.fromString(body.count.toJson().toString(), contentType: DioMediaType.parse('application/json'))));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'status': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.status != null) {
              formData.files.add(MapEntry('status', MultipartFile.fromString(body.status!.toJson(), contentType: DioMediaType.parse('text/plain'))));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'status': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.status != null) {
              formData.files.add(MapEntry('status', MultipartFile.fromString(body.status!.toJson(), contentType: DioMediaType.parse('text/plain'))));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'avatar': const MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            switch (body.avatar) {
              case TonikFileBytes(:final bytes, :final fileName):
                formData.files.add(MapEntry(
                  'avatar',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? 'avatar'),
                ));
              case TonikFilePath(:final path, :final fileName):
                formData.files.add(MapEntry(
                  'avatar',
                  await MultipartFile.fromFile(path, filename: fileName ?? 'avatar'),
                ));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'document': const MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.document != null) {
              switch (body.document!) {
                case TonikFileBytes(:final bytes, :final fileName):
                  formData.files.add(MapEntry(
                    'document',
                    MultipartFile.fromBytes(bytes, filename: fileName ?? 'document'),
                  ));
                case TonikFilePath(:final path, :final fileName):
                  formData.files.add(MapEntry(
                    'document',
                    await MultipartFile.fromFile(path, filename: fileName ?? 'document'),
                  ));
              }
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'photo': const MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.photo != null) {
              switch (body.photo!) {
                case TonikFileBytes(:final bytes, :final fileName):
                  formData.files.add(MapEntry(
                    'photo',
                    MultipartFile.fromBytes(bytes, filename: fileName ?? 'photo'),
                  ));
                case TonikFilePath(:final path, :final fileName):
                  formData.files.add(MapEntry(
                    'photo',
                    await MultipartFile.fromFile(path, filename: fileName ?? 'photo'),
                  ));
              }
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'image': const MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'image/png',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            switch (body.image) {
              case TonikFileBytes(:final bytes, :final fileName):
                formData.files.add(MapEntry(
                  'image',
                  MultipartFile.fromBytes(
                    bytes,
                    filename: fileName ?? 'image',
                    contentType: DioMediaType.parse('image/png'),
                  ),
                ));
              case TonikFilePath(:final path, :final fileName):
                formData.files.add(MapEntry(
                  'image',
                  await MultipartFile.fromFile(
                    path,
                    filename: fileName ?? 'image',
                    contentType: DioMediaType.parse('image/png'),
                  ),
                ));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'file': const MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? 'file'),
                ));
              case TonikFilePath(:final path, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? 'file'),
                ));
            }
          }
        '''),
        ),
      );
    });
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'address': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: MultipartEncodingStyle.form,
              explode: true,
              allowReserved: false,
            ),
          },
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
            final formData = FormData();
            formData.files.add(MapEntry(
              'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse('application/json'),
              ),
            ));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'address': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry(
              'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse('application/json'),
              ),
            ));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'address': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry(
              'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse('application/json'),
              ),
            ));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'address': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry(
              'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse('application/json'),
              ),
            ));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'address': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.address != null) {
              formData.files.add(MapEntry(
                'address',
                MultipartFile.fromString(
                  jsonEncode(body.address!.toJson()),
                  contentType: DioMediaType.parse('application/json'),
                ),
              ));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'address': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.address != null) {
              formData.files.add(MapEntry(
                'address',
                MultipartFile.fromString(
                  jsonEncode(body.address!.toJson()),
                  contentType: DioMediaType.parse('application/json'),
                ),
              ));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'address': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/xml',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry(
              'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse('application/xml'),
              ),
            ));
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'address': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: MultipartEncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
            ),
          },
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
              final formData = FormData();
              for (final entry in body.address
                  .toDeepObject(r'address', explode: true, allowEmpty: true)) {
                formData.fields.add(MapEntry(entry.name, entry.value));
              }
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'address': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: MultipartEncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
            ),
          },
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
              final formData = FormData();
              if (body.address != null) {
                for (final entry in body.address!
                    .toDeepObject(r'address', explode: true, allowEmpty: true)) {
                  formData.fields.add(MapEntry(entry.name, entry.value));
                }
              }
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'address': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: MultipartEncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
            ),
          },
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
              final formData = FormData();
              for (final entry in body.address
                  .toDeepObject(r'address', explode: true, allowEmpty: true)) {
                formData.fields.add(MapEntry(entry.name, entry.value));
              }
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'address': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: MultipartEncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
            ),
          },
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
              final formData = FormData();
              for (final entry in body.address
                  .toDeepObject(r'address', explode: true, allowEmpty: true)) {
                formData.fields.add(MapEntry(entry.name, entry.value));
              }
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'address': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              style: MultipartEncodingStyle.deepObject,
              explode: true,
              allowReserved: false,
            ),
          },
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
              final formData = FormData();
              for (final entry in body.address
                  .toDeepObject(r'address', explode: true, allowEmpty: true)) {
                formData.fields.add(MapEntry(entry.name, entry.value));
              }
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
      );

      final aliasModel = AliasModel(
        name: 'AddressAlias',
        model: innerClass,
        context: testContext,
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'address': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            formData.files.add(MapEntry(
              'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse('application/json'),
              ),
            ));
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
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'address': const MultipartPropertyEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                // No style/explode/allowReserved → content-based mode
              ),
            },
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
                final formData = FormData();
                final addressParts = <String>[];
                for (final entry in (body.address.toJson() as Map).entries) {
                  final value = entry.value;
                  if (value == null) continue;
                  if (value is Map) {
                    for (final subEntry in value.entries) {
                      final subValue = subEntry.value;
                      if (subValue == null) continue;
                      if (subValue is Map) {
                        throw EncodingException(
                          'URL-encoded part encoding does not support nesting deeper than '
                          'one level (property: address, key: ${entry.key}).',
                        );
                      }
                      addressParts.add(
                        '${Uri.encodeQueryComponent(entry.key)}[${Uri.encodeQueryComponent(subEntry.key)}]=${Uri.encodeQueryComponent(subValue.toString())}',
                      );
                    }
                  } else {
                    addressParts.add(
                      '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value.toString())}',
                    );
                  }
                }
                formData.files.add(MapEntry(
                  'address',
                  MultipartFile.fromString(
                    addressParts.join('&'),
                    contentType: DioMediaType.parse(
                      'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
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
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'address': const MultipartPropertyEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
              ),
            },
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
                final formData = FormData();
                final addressParts = <String>[];
                for (final entry in (body.address.toJson() as Map).entries) {
                  final value = entry.value;
                  if (value == null) continue;
                  if (value is Map) {
                    for (final subEntry in value.entries) {
                      final subValue = subEntry.value;
                      if (subValue == null) continue;
                      if (subValue is Map) {
                        throw EncodingException(
                          'URL-encoded part encoding does not support nesting deeper than '
                          'one level (property: address, key: ${entry.key}).',
                        );
                      }
                      addressParts.add(
                        '${Uri.encodeQueryComponent(entry.key)}[${Uri.encodeQueryComponent(subEntry.key)}]=${Uri.encodeQueryComponent(subValue.toString())}',
                      );
                    }
                  } else {
                    addressParts.add(
                      '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value.toString())}',
                    );
                  }
                }
                formData.files.add(MapEntry(
                  'address',
                  MultipartFile.fromString(
                    addressParts.join('&'),
                    contentType: DioMediaType.parse(
                      'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'address': const MultipartPropertyEncoding(
              contentType: ContentType.form,
              rawContentType: 'application/x-www-form-urlencoded',
            ),
          },
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
              final formData = FormData();
              if (body.address != null) {
                final addressParts = <String>[];
                for (final entry in (body.address!.toJson() as Map).entries) {
                  final value = entry.value;
                  if (value == null) continue;
                  if (value is Map) {
                    for (final subEntry in value.entries) {
                      final subValue = subEntry.value;
                      if (subValue == null) continue;
                      if (subValue is Map) {
                        throw EncodingException(
                          'URL-encoded part encoding does not support nesting deeper than '
                          'one level (property: address, key: ${entry.key}).',
                        );
                      }
                      addressParts.add(
                        '${Uri.encodeQueryComponent(entry.key)}[${Uri.encodeQueryComponent(subEntry.key)}]=${Uri.encodeQueryComponent(subValue.toString())}',
                      );
                    }
                  } else {
                    addressParts.add(
                      '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value.toString())}',
                    );
                  }
                }
                formData.files.add(MapEntry(
                  'address',
                  MultipartFile.fromString(
                    addressParts.join('&'),
                    contentType: DioMediaType.parse(
                      'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
              }
            }
          '''),
          ),
        );
      });

      test(
        'style-based mode with URL-encoded contentType uses JSON serialization',
        () {
          final innerClass = ClassModel(
            name: 'Address',
            isDeprecated: false,
            properties: [],
            context: testContext,
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
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'address': const MultipartPropertyEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                // style/explode present → style-based mode, contentType ignored
                style: MultipartEncodingStyle.form,
                explode: true,
                allowReserved: false,
              ),
            },
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
                final formData = FormData();
                formData.files.add(MapEntry(
                  'address',
                  MultipartFile.fromString(
                    jsonEncode(body.address.toJson()),
                    contentType: DioMediaType.parse(
                      'application/x-www-form-urlencoded',
                    ),
                  ),
                ));
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
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'address': MultipartPropertyEncoding(
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
                  ),
                },
              ),
            },
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
                final formData = FormData();
                final addressHeaders = <String, List<String>>{};
                addressHeaders['X-Custom-Header'] = [
                  addressCustomHeader.toSimple(explode: false, allowEmpty: true),
                ];
                final addressParts = <String>[];
                for (final entry in (body.address.toJson() as Map).entries) {
                  final value = entry.value;
                  if (value == null) continue;
                  if (value is Map) {
                    for (final subEntry in value.entries) {
                      final subValue = subEntry.value;
                      if (subValue == null) continue;
                      if (subValue is Map) {
                        throw EncodingException(
                          'URL-encoded part encoding does not support nesting deeper than '
                          'one level (property: address, key: ${entry.key}).',
                        );
                      }
                      addressParts.add(
                        '${Uri.encodeQueryComponent(entry.key)}[${Uri.encodeQueryComponent(subEntry.key)}]=${Uri.encodeQueryComponent(subValue.toString())}',
                      );
                    }
                  } else {
                    addressParts.add(
                      '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value.toString())}',
                    );
                  }
                }
                formData.files.add(MapEntry(
                  'address',
                  MultipartFile.fromString(
                    addressParts.join('&'),
                    contentType: DioMediaType.parse(
                      'application/x-www-form-urlencoded',
                    ),
                    headers: addressHeaders,
                  ),
                ));
              }
            '''),
            ),
          );
        },
      );
    });
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'tags': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.tags) {
              formData.fields.add(MapEntry('tags', item));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'tags': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.spaceDelimited,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.tags) {
              formData.fields.add(MapEntry('tags', item));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'tags': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: false,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.tags.toForm(explode: false, allowEmpty: true, alreadyEncoded: true)) {
              formData.fields.add(MapEntry('tags', item));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'tags': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.spaceDelimited,
            explode: false,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.tags.toSpaceDelimited(explode: false, allowEmpty: true, alreadyEncoded: true, percentEncodeDelimiter: false)) {
              formData.fields.add(MapEntry('tags', item));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'tags': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.pipeDelimited,
            explode: false,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.tags.toPipeDelimited(explode: false, allowEmpty: true, alreadyEncoded: true)) {
              formData.fields.add(MapEntry('tags', item));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'tags': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.deepObject,
            explode: false,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            throw EncodingException(
              'deepObject style is not supported for array multipart properties (property: tags).',
            );
          }
        '''),
        ),
      );
    });

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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'statuses': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.statuses) {
              formData.fields.add(MapEntry('statuses', item.uriEncode(allowEmpty: true)));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'codes': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: false,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.codes.map((item) => item.uriEncode(allowEmpty: true)).toList().toForm(explode: false, allowEmpty: true, alreadyEncoded: true)) {
              formData.fields.add(MapEntry('codes', item));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'scores': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.scores) {
              formData.fields.add(MapEntry('scores', item.toString()));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'scores': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.scores) {
              formData.fields.add(MapEntry('scores', jsonEncode(item)));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'scores': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: false,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.scores.map((item) => jsonEncode(item)).toList().toForm(explode: false, allowEmpty: true, alreadyEncoded: true)) {
              formData.fields.add(MapEntry('scores', item));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'dates': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.dates) {
              formData.fields.add(MapEntry('dates', item.toTimeZonedIso8601String()));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'dates': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.dates) {
              formData.fields.add(MapEntry('dates', jsonEncode(item)));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'files': const MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.files) {
              switch (item) {
                case TonikFileBytes(:final bytes, :final fileName):
                  formData.files.add(MapEntry('files', MultipartFile.fromBytes(bytes, filename: fileName ?? 'files')));
                case TonikFilePath(:final path, :final fileName):
                  formData.files.add(MapEntry('files', await MultipartFile.fromFile(path, filename: fileName ?? 'files')));
              }
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'files': const MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: MultipartEncodingStyle.form,
            explode: false,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.files) {
              switch (item) {
                case TonikFileBytes(:final bytes, :final fileName):
                  formData.files.add(MapEntry('files', MultipartFile.fromBytes(bytes, filename: fileName ?? 'files')));
                case TonikFilePath(:final path, :final fileName):
                  formData.files.add(MapEntry('files', await MultipartFile.fromFile(path, filename: fileName ?? 'files')));
              }
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'addresses': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.addresses) {
              formData.files.add(MapEntry('addresses', MultipartFile.fromString(jsonEncode(item.toJson()), contentType: DioMediaType.parse('application/json'))));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'addresses': const MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/xml',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            for (final item in body.addresses) {
              formData.files.add(MapEntry('addresses', MultipartFile.fromString(jsonEncode(item.toJson()), contentType: DioMediaType.parse('application/xml'))));
            }
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
            ),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'tags': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.tags != null) {
              for (final item in body.tags!) {
                formData.fields.add(MapEntry('tags', item));
              }
            }
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
            ),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'tags': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
            final formData = FormData();
            if (body.tags != null) {
              for (final item in body.tags!) {
                formData.fields.add(MapEntry('tags', item));
              }
            }
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
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'tags': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
          },
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
              final formData = FormData();
              formData.files.add(MapEntry('tags', MultipartFile.fromString(jsonEncode(body.tags), contentType: DioMediaType.parse('application/json'))));
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
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'scores': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
          },
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
              final formData = FormData();
              formData.files.add(MapEntry('scores', MultipartFile.fromString(jsonEncode(body.scores), contentType: DioMediaType.parse('application/json'))));
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
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
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
              final formData = FormData();
              for (final item in body.tags) {
                formData.fields.add(MapEntry('tags', item));
              }
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
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'addresses': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
          },
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
              final formData = FormData();
              formData.files.add(MapEntry('addresses', MultipartFile.fromString(jsonEncode(body.addresses.map((e) => e.toJson()).toList()), contentType: DioMediaType.parse('application/json'))));
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
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'dates': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
          },
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
              final formData = FormData();
              formData.files.add(MapEntry('dates', MultipartFile.fromString(jsonEncode(body.dates.map((e) => e.toTimeZonedIso8601String()).toList()), contentType: DioMediaType.parse('application/json'))));
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
              ),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'tags': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
          },
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
              final formData = FormData();
              if (body.tags != null) {
                formData.files.add(MapEntry('tags', MultipartFile.fromString(jsonEncode(body.tags!), contentType: DioMediaType.parse('application/json'))));
              }
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
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'tags': const MultipartPropertyEncoding(
                contentType: ContentType.text,
                rawContentType: 'text/plain',
                // No style/explode/allowReserved → falls through to explode: true
              ),
            },
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
                final formData = FormData();
                for (final item in body.tags) {
                  formData.fields.add(MapEntry('tags', item));
                }
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
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'scores': const MultipartPropertyEncoding(
                contentType: ContentType.text,
                rawContentType: 'text/plain',
                // No style/explode/allowReserved → repeated parts
              ),
            },
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
                final formData = FormData();
                for (final item in body.scores) {
                  formData.fields.add(MapEntry('scores', item.toString()));
                }
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
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'dates': const MultipartPropertyEncoding(
                contentType: ContentType.text,
                rawContentType: 'text/plain',
                // No style/explode/allowReserved → repeated parts
              ),
            },
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
                final formData = FormData();
                for (final item in body.dates) {
                  formData.fields.add(MapEntry('dates', item.toTimeZonedIso8601String()));
                }
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
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'priorities': const MultipartPropertyEncoding(
                contentType: ContentType.text,
                rawContentType: 'text/plain',
                // No style/explode/allowReserved → repeated parts
              ),
            },
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
                final formData = FormData();
                for (final item in body.priorities) {
                  formData.fields.add(MapEntry('priorities', item.uriEncode(allowEmpty: true)));
                }
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
                ),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
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
                final formData = FormData();
                if (body.tags != null) {
                  for (final item in body.tags!) {
                    formData.fields.add(MapEntry('tags', item));
                  }
                }
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
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'priorities': const MultipartPropertyEncoding(
              contentType: ContentType.json,
              rawContentType: 'application/json',
              // No style fields → content-based mode
            ),
          },
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
              final formData = FormData();
              formData.files.add(MapEntry('priorities', MultipartFile.fromString(jsonEncode(body.priorities.map((e) => e.uriEncode(allowEmpty: true)).toList()), contentType: DioMediaType.parse('application/json'))));
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
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'files': const MultipartPropertyEncoding(
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                // No style/explode/allowReserved → content-based mode
              ),
            },
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
                final formData = FormData();
                for (final item in body.files) {
                  switch (item) {
                    case TonikFileBytes(:final bytes, :final fileName):
                      formData.files.add(MapEntry('files', MultipartFile.fromBytes(bytes, filename: fileName ?? 'files')));
                    case TonikFilePath(:final path, :final fileName):
                      formData.files.add(MapEntry('files', await MultipartFile.fromFile(path, filename: fileName ?? 'files')));
                  }
                }
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
                  ),
                  context: testContext,
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'matrix': const MultipartPropertyEncoding(
                contentType: ContentType.json,
                rawContentType: 'application/json',
                // No style fields → content-based mode
              ),
            },
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
                final formData = FormData();
                throw EncodingException(
                  'Arrays of arrays are not supported for multipart encoding (property: matrix).',
                );
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
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: testContext,
          );

          final content = RequestContent(
            model: model,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'items': const MultipartPropertyEncoding(
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                // No style fields → content-based mode
              ),
            },
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
                final formData = FormData();
                throw EncodingException(
                  'Unsupported contentType "application/x-www-form-urlencoded" for array multipart property "items". Only application/json is supported for content-based array serialization.',
                );
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'name': const MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
            explode: true,
            allowReserved: false,
          ),
        },
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
              final formData = FormData();
              formData.files.add(MapEntry('name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse('text/plain'))));
              return formData;
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'file': MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: MultipartEncodingStyle.form,
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
              ),
            },
          ),
        },
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
            final formData = FormData();
            final fileHeaders = <String, List<String>>{};
            fileHeaders['X-Rate-Limit'] = [fileRateLimit.toSimple(explode: false, allowEmpty: true)];
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? 'file', headers: fileHeaders),
                ));
              case TonikFilePath(:final path, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? 'file', headers: fileHeaders),
                ));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'file': MultipartPropertyEncoding(
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
              ),
            },
          ),
        },
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
            final formData = FormData();
            final fileHeaders = <String, List<String>>{};
            if (fileTag != null) {
              fileHeaders['X-Tag'] = [fileTag.toSimple(explode: false, allowEmpty: true)];
            }
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? 'file', headers: fileHeaders),
                ));
              case TonikFilePath(:final path, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? 'file', headers: fileHeaders),
                ));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'address': MultipartPropertyEncoding(
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
              ),
            },
          ),
        },
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
            final formData = FormData();
            final addressHeaders = <String, List<String>>{};
            addressHeaders['X-Custom'] = [addressCustom.toSimple(explode: false, allowEmpty: true)];
            formData.files.add(MapEntry(
              'address',
              MultipartFile.fromString(
                jsonEncode(body.address.toJson()),
                contentType: DioMediaType.parse('application/json'),
                headers: addressHeaders,
              ),
            ));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'description': MultipartPropertyEncoding(
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
              ),
            },
          ),
        },
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
            final formData = FormData();
            final descriptionHeaders = <String, List<String>>{};
            descriptionHeaders['X-Language'] = [descriptionLanguage.toSimple(explode: false, allowEmpty: true)];
            formData.files.add(MapEntry(
              'description',
              MultipartFile.fromString(body.description, contentType: DioMediaType.parse('text/plain'), headers: descriptionHeaders),
            ));
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'count': MultipartPropertyEncoding(
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
                ),
              },
            ),
          },
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
            final formData = FormData();
            final countHeaders = <String, List<String>>{};
            countHeaders['X-Source'] = [countSource.toSimple(explode: false, allowEmpty: true)];
            formData.files.add(MapEntry(
              'count',
              MultipartFile.fromString(body.count.toString(), contentType: DioMediaType.parse('text/plain'), headers: countHeaders),
            ));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'status': MultipartPropertyEncoding(
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
              ),
            },
          ),
        },
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
            final formData = FormData();
            final statusHeaders = <String, List<String>>{};
            statusHeaders['X-Custom'] = [statusCustom.toSimple(explode: false, allowEmpty: true)];
            formData.files.add(MapEntry(
              'status',
              MultipartFile.fromString(body.status.toJson(), contentType: DioMediaType.parse('text/plain'), headers: statusHeaders),
            ));
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'file': MultipartPropertyEncoding(
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
              ),
            },
          ),
        },
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
          format('''
          void test() {
            final formData = FormData();
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? 'file'),
                ));
              case TonikFilePath(:final path, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? 'file'),
                ));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'file': MultipartPropertyEncoding(
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
              ),
            },
          ),
        },
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
            final formData = FormData();
            final fileHeaders = <String, List<String>>{};
            fileHeaders['X-Rate-Limit'] = [fileRateLimit.toSimple(explode: false, allowEmpty: true)];
            if (fileTag != null) {
              fileHeaders['X-Tag'] = [fileTag.toSimple(explode: false, allowEmpty: true)];
            }
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? 'file', headers: fileHeaders),
                ));
              case TonikFilePath(:final path, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? 'file', headers: fileHeaders),
                ));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'file': const MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
          ),
        },
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
            final formData = FormData();
            switch (body.file) {
              case TonikFileBytes(:final bytes, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? 'file'),
                ));
              case TonikFilePath(:final path, :final fileName):
                formData.files.add(MapEntry(
                  'file',
                  await MultipartFile.fromFile(path, filename: fileName ?? 'file'),
                ));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'tags': MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
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
              ),
            },
          ),
        },
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
            final formData = FormData();
            final tagsHeaders = <String, List<String>>{};
            tagsHeaders['X-Custom'] = [tagsCustom.toSimple(explode: false, allowEmpty: true)];
            for (final item in body.tags) {
              formData.files.add(MapEntry('tags', MultipartFile.fromString(item, headers: tagsHeaders)));
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'tags': MultipartPropertyEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: MultipartEncodingStyle.form,
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
              ),
            },
          ),
        },
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
            final formData = FormData();
            final tagsHeaders = <String, List<String>>{};
            tagsHeaders['X-Custom'] = [tagsCustom.toSimple(explode: false, allowEmpty: true)];
            for (final item in body.tags.toForm(explode: false, allowEmpty: true, alreadyEncoded: true)) {
              formData.files.add(MapEntry('tags', MultipartFile.fromString(item, headers: tagsHeaders)));
            }
          }
        '''),
        ),
      );
    });

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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'files': MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            style: MultipartEncodingStyle.form,
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
              ),
            },
          ),
        },
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
            final formData = FormData();
            final filesHeaders = <String, List<String>>{};
            filesHeaders['X-Checksum'] = [filesChecksum.toSimple(explode: false, allowEmpty: true)];
            for (final item in body.files) {
              switch (item) {
                case TonikFileBytes(:final bytes, :final fileName):
                  formData.files.add(MapEntry('files', MultipartFile.fromBytes(bytes, filename: fileName ?? 'files', headers: filesHeaders)));
                case TonikFilePath(:final path, :final fileName):
                  formData.files.add(MapEntry('files', await MultipartFile.fromFile(path, filename: fileName ?? 'files', headers: filesHeaders)));
              }
            }
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
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'addresses': MultipartPropertyEncoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
            style: MultipartEncodingStyle.form,
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
              ),
            },
          ),
        },
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
            final formData = FormData();
            final addressesHeaders = <String, List<String>>{};
            addressesHeaders['X-Custom'] = [addressesCustom.toSimple(explode: false, allowEmpty: true)];
            for (final item in body.addresses) {
              formData.files.add(MapEntry('addresses', MultipartFile.fromString(jsonEncode(item.toJson()), contentType: DioMediaType.parse('application/json'), headers: addressesHeaders)));
            }
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
          ),
        ],
        context: testContext,
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'file': MultipartPropertyEncoding(
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
              ),
            },
          ),
        },
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
          format('''
          void test() {
            final formData = FormData();
            if (body.file != null) {
              final fileHeaders = <String, List<String>>{};
              fileHeaders['X-Rate-Limit'] = [fileRateLimit!.toSimple(explode: false, allowEmpty: true)];
              switch (body.file!) {
                case TonikFileBytes(:final bytes, :final fileName):
                  formData.files.add(MapEntry(
                    'file',
                    MultipartFile.fromBytes(bytes, filename: fileName ?? 'file', headers: fileHeaders),
                  ));
                case TonikFilePath(:final path, :final fileName):
                  formData.files.add(MapEntry(
                    'file',
                    await MultipartFile.fromFile(path, filename: fileName ?? 'file', headers: fileHeaders),
                  ));
              }
            }
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'file': MultipartPropertyEncoding(
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
                ),
              },
            ),
          },
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
            final formData = FormData();
            if (body.file != null) {
              final fileHeaders = <String, List<String>>{};
              fileHeaders['X-Checksum'] = [fileChecksum!.toSimple(explode: false, allowEmpty: true)];
              switch (body.file!) {
                case TonikFileBytes(:final bytes, :final fileName):
                  formData.files.add(MapEntry(
                    'file',
                    MultipartFile.fromBytes(bytes, filename: fileName ?? 'file', headers: fileHeaders),
                  ));
                case TonikFilePath(:final path, :final fileName):
                  formData.files.add(MapEntry(
                    'file',
                    await MultipartFile.fromFile(path, filename: fileName ?? 'file', headers: fileHeaders),
                  ));
              }
            }
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'data': MultipartPropertyEncoding(
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
                ),
              },
            ),
          },
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
            final formData = FormData();
            final dataHeaders = <String, List<String>>{};
            dataHeaders['X-Custom'] = [dataCustom.toSimple(explode: false, allowEmpty: true)];
            formData.files.add(MapEntry(
              'data',
              MultipartFile.fromString(body.data.toString(), contentType: DioMediaType.parse('text/plain'), headers: dataHeaders),
            ));
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'count': MultipartPropertyEncoding(
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
                ),
              },
            ),
          },
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
            final formData = FormData();
            final countHeaders = <String, List<String>>{};
            countHeaders['X-Source'] = [countSource.toSimple(explode: false, allowEmpty: true)];
            formData.files.add(MapEntry(
              'count',
              MultipartFile.fromString(jsonEncode(body.count), contentType: DioMediaType.parse('application/json'), headers: countHeaders),
            ));
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
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'createdAt': MultipartPropertyEncoding(
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
                ),
              },
            ),
          },
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
            final formData = FormData();
            final createdAtHeaders = <String, List<String>>{};
            createdAtHeaders['X-Source'] = [createdAtSource.toSimple(explode: false, allowEmpty: true)];
            formData.files.add(MapEntry(
              'createdAt',
              MultipartFile.fromString(jsonEncode(body.createdAt), contentType: DioMediaType.parse('application/json'), headers: createdAtHeaders),
            ));
          }
        '''),
          ),
        );
      },
    );

    test(
      'non-exploded DateTime list with headers uses item directly '
      'after encoder stringifies',
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
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: testContext,
        );

        final content = RequestContent(
          model: model,
          contentType: ContentType.multipart,
          rawContentType: 'multipart/form-data',
          encoding: {
            'dates': MultipartPropertyEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              style: MultipartEncodingStyle.form,
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
                ),
              },
            ),
          },
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
            final formData = FormData();
            final datesHeaders = <String, List<String>>{};
            datesHeaders['X-Custom'] = [datesCustom.toSimple(explode: false, allowEmpty: true)];
            for (final item in body.dates.map((item) => item.toTimeZonedIso8601String()).toList().toForm(explode: false, allowEmpty: true, alreadyEncoded: true)) {
              formData.files.add(MapEntry('dates', MultipartFile.fromString(item, headers: datesHeaders)));
            }
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
          ),
        ],
        context: testContext,
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
      );

      final content = RequestContent(
        model: model,
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        encoding: {
          'document': MultipartPropertyEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            headers: {
              'X-Trace-Id': ResponseHeaderAlias(
                name: 'X-Trace-Id',
                context: testContext,
                header: underlyingHeader,
              ),
            },
          ),
        },
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
          format('''
          void test() {
            final formData = FormData();
            final documentHeaders = <String, List<String>>{};
            documentHeaders['X-Trace-Id'] = [documentTraceId.toSimple(explode: false, allowEmpty: true)];
            switch (body.document) {
              case TonikFileBytes(:final bytes, :final fileName):
                formData.files.add(MapEntry(
                  'document',
                  MultipartFile.fromBytes(bytes, filename: fileName ?? 'document', headers: documentHeaders),
                ));
              case TonikFilePath(:final path, :final fileName):
                formData.files.add(MapEntry(
                  'document',
                  await MultipartFile.fromFile(path, filename: fileName ?? 'document', headers: documentHeaders),
                ));
            }
          }
        '''),
        ),
      );
    });
  });
}
