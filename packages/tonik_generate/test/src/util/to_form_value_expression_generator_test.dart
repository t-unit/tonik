import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/to_form_value_expression_generator.dart';

void main() {
  late Context context;
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(
      useNullSafetySyntax: true,
      allocator: CorePrefixedAllocator(),
    );
  });

  String bodyOf(BuiltExpression built) {
    final method = Method(
      (b) => b
        ..name = 'test'
        ..body = built.expression.statement,
    );
    return format(method.accept(emitter).toString());
  }

  group('buildToFormValueExpression', () {
    test('ClassModel body expands entries to a joined key=value string', () {
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: const [],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body threads a fieldEncodings map for flagged '
        'properties', () {
      final reserved = Property(
        name: 'reserved',
        model: StringModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final plain = Property(
        name: 'plain',
        model: StringModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [reserved, plain],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
        encoding: {
          reserved: const FieldEncoding(
            allowReserved: true,
            style: null,
            explode: null,
          ),
          plain: const FieldEncoding(
            allowReserved: false,
            style: null,
            explode: null,
          ),
        },
      );

      final expected = format(r'''
        test() {
          body
              .toForm(
                '',
                explode: true,
                allowEmpty: true,
                useQueryComponent: true,
                fieldEncodings: <_i1.String, _i2.FormFieldEncoding>{
                  r'reserved': const _i2.FormFieldEncoding(allowReserved: true),
                },
              )
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body omits fieldEncodings when no property opts in', () {
      final plain = Property(
        name: 'plain',
        model: StringModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [plain],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
        encoding: {
          plain: const FieldEncoding(
            allowReserved: false,
            style: null,
            explode: null,
          ),
        },
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body excludes a read-only property from '
        'fieldEncodings', () {
      final hidden = Property(
        name: 'hidden',
        model: StringModel(context: context),
        isRequired: true,
        isNullable: false,
        isReadOnly: true,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [hidden],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
        encoding: {
          hidden: const FieldEncoding(
            allowReserved: true,
            style: null,
            explode: null,
          ),
        },
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body threads a fieldEncodings map for a flagged array '
        'property', () {
      final tags = Property(
        name: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [tags],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
        encoding: {
          tags: const FieldEncoding(
            allowReserved: true,
            style: null,
            explode: null,
          ),
        },
      );

      final expected = format(r'''
        test() {
          body
              .toForm(
                '',
                explode: true,
                allowEmpty: true,
                useQueryComponent: true,
                fieldEncodings: <_i1.String, _i2.FormFieldEncoding>{
                  r'tags': const _i2.FormFieldEncoding(
                    allowReserved: true,
                    explode: true,
                  ),
                },
              )
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body defaults an array property to explode=true with no '
        'encoding', () {
      final colors = Property(
        name: 'colors',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [colors],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm(
                '',
                explode: true,
                allowEmpty: true,
                useQueryComponent: true,
                fieldEncodings: <_i1.String, _i2.FormFieldEncoding>{
                  r'colors': const _i2.FormFieldEncoding(explode: true),
                },
              )
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body threads explode=false for an array property that '
        'opts out', () {
      final colors = Property(
        name: 'colors',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [colors],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
        encoding: {
          colors: const FieldEncoding(
            allowReserved: false,
            style: null,
            explode: false,
          ),
        },
      );

      final expected = format(r'''
        test() {
          body
              .toForm(
                '',
                explode: true,
                allowEmpty: true,
                useQueryComponent: true,
                fieldEncodings: <_i1.String, _i2.FormFieldEncoding>{
                  r'colors': const _i2.FormFieldEncoding(explode: false),
                },
              )
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body defaults an explicit form-style array property to '
        'explode=true when the encoding omits explode', () {
      final colors = Property(
        name: 'colors',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [colors],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
        encoding: {
          colors: const FieldEncoding(
            style: EncodingStyle.form,
            explode: null,
            allowReserved: false,
          ),
        },
      );

      final expected = format(r'''
        test() {
          body
              .toForm(
                '',
                explode: true,
                allowEmpty: true,
                useQueryComponent: true,
                fieldEncodings: <_i1.String, _i2.FormFieldEncoding>{
                  r'colors': const _i2.FormFieldEncoding(explode: true),
                },
              )
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body defaults a pipeDelimited array property to '
        'explode=false when the encoding omits explode', () {
      final tags = Property(
        name: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [tags],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
        encoding: {
          tags: const FieldEncoding(
            allowReserved: false,
            style: EncodingStyle.pipeDelimited,
            explode: null,
          ),
        },
      );

      final expected = format(r'''
        test() {
          body
              .toForm(
                '',
                explode: true,
                allowEmpty: true,
                useQueryComponent: true,
                fieldEncodings: <_i1.String, _i2.FormFieldEncoding>{
                  r'tags': const _i2.FormFieldEncoding(explode: false),
                },
              )
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body explodes a pipeDelimited array property when the '
        'encoding sets explode=true', () {
      final tags = Property(
        name: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [tags],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
        encoding: {
          tags: const FieldEncoding(
            allowReserved: false,
            style: EncodingStyle.pipeDelimited,
            explode: true,
          ),
        },
      );

      final expected = format(r'''
        test() {
          body
              .toForm(
                '',
                explode: true,
                allowEmpty: true,
                useQueryComponent: true,
                fieldEncodings: <_i1.String, _i2.FormFieldEncoding>{
                  r'tags': const _i2.FormFieldEncoding(explode: true),
                },
              )
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('AllOf body flags an array member property with explode=true in '
        'fieldEncodings', () {
      final tags = Property(
        name: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final member = ClassModel(
        name: 'Member',
        isDeprecated: false,
        properties: [tags],
        context: context,
        examples: const [],
      );
      final model = AllOfModel(
        name: 'Form',
        models: {member},
        context: context,
        isDeprecated: false,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm(
                '',
                explode: true,
                allowEmpty: true,
                useQueryComponent: true,
                fieldEncodings: <_i1.String, _i2.FormFieldEncoding>{
                  r'tags': const _i2.FormFieldEncoding(explode: true),
                },
              )
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('AllOf body with a duplicate raw name across a list and a scalar '
        'member keys the descriptor from the sorted-last member', () {
      final listMember = ClassModel(
        name: 'ZListMember',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );
      final scalarMember = ClassModel(
        name: 'AScalarMember',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );
      final model = AllOfModel(
        name: 'Form',
        models: {listMember, scalarMember},
        context: context,
        isDeprecated: false,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm(
                '',
                explode: true,
                allowEmpty: true,
                useQueryComponent: true,
                fieldEncodings: <_i1.String, _i2.FormFieldEncoding>{
                  r'tags': const _i2.FormFieldEncoding(explode: true),
                },
              )
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body excludes a read-only array property from '
        'fieldEncodings', () {
      final tags = Property(
        name: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        isReadOnly: true,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [tags],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('AllOf body with a duplicate raw name whose scalar member sorts last '
        'omits the descriptor key', () {
      final listMember = ClassModel(
        name: 'AListMember',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );
      final scalarMember = ClassModel(
        name: 'ZScalarMember',
        isDeprecated: false,
        properties: [
          Property(
            name: 'tags',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );
      final model = AllOfModel(
        name: 'Form',
        models: {listMember, scalarMember},
        context: context,
        isDeprecated: false,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('oneOf body yields no explode descriptors for its array properties',
        () {
      final tags = Property(
        name: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final variant = ClassModel(
        name: 'Variant',
        isDeprecated: false,
        properties: [tags],
        context: context,
        examples: const [],
      );
      final model = OneOfModel(
        name: 'Form',
        models: {(discriminatorValue: null, model: variant)},
        context: context,
        isDeprecated: false,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('anyOf body yields no explode descriptors for its array properties',
        () {
      final tags = Property(
        name: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final variant = ClassModel(
        name: 'Variant',
        isDeprecated: false,
        properties: [tags],
        context: context,
        examples: const [],
      );
      final model = AnyOfModel(
        name: 'Form',
        models: {(discriminatorValue: null, model: variant)},
        context: context,
        isDeprecated: false,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel body omits the explode descriptor for an alias-wrapped '
        'array property', () {
      final tags = Property(
        name: 'tags',
        model: AliasModel(
          name: 'Tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          context: context,
          defaultValue: null,
          examples: const [],
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: [tags],
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('AnyModel body renders directly via encodeAnyToForm', () {
      final result = buildToFormValueExpression(
        'body',
        AnyModel(context: context),
        useQueryComponent: true,
      );

      final expected = format('''
        test() {
          _i1.encodeAnyToForm(
            body,
            explode: true,
            allowEmpty: true,
            useQueryComponent: true,
          );
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('AnyModel body omits useQueryComponent when false', () {
      final result = buildToFormValueExpression(
        'body',
        AnyModel(context: context),
        useQueryComponent: false,
      );

      final expected = format('''
        test() {
          _i1.encodeAnyToForm(body, explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('MapModel body throws an encoding exception', () {
      final model = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format('''
        test() {
          throw _i1.EncodingException('Form encoding not supported for map types.');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('BinaryModel body throws an encoding exception', () {
      final result = buildToFormValueExpression(
        'body',
        BinaryModel(context: context),
        useQueryComponent: true,
      );

      final expected = format('''
        test() {
          throw _i1.EncodingException('Binary data cannot be form-encoded.');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('NeverModel body throws an encoding exception', () {
      final result = buildToFormValueExpression(
        'body',
        NeverModel(context: context),
        useQueryComponent: true,
      );

      final expected = format('''
        test() {
          throw _i1.EncodingException(
            'Cannot encode NeverModel - this type does not permit any value.',
          );
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('list with complex content throws an unsupported encoding '
        'exception', () {
      final model = ListModel(
        content: ClassModel(
          name: 'Item',
          properties: const [],
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format('''
        test() {
          throw _i1.EncodingException(
            'Unsupported model type for form encoding.',
          );
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('StringModel body renders the bare value without a key', () {
      final result = buildToFormValueExpression(
        'body',
        StringModel(context: context),
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('IntegerModel body renders the bare value without a key', () {
      final result = buildToFormValueExpression(
        'body',
        IntegerModel(context: context),
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('EnumModel body renders the bare value without a key', () {
      final model = EnumModel<String>(
        name: 'Status',
        values: {
          const EnumEntry<String>(value: 'active'),
          const EnumEntry<String>(value: 'inactive'),
        },
        isNullable: false,
        isDeprecated: false,
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ListModel body renders comma-joined values without a key', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
        examples: const [],
      );

      final result = buildToFormValueExpression(
        'body',
        model,
        useQueryComponent: true,
      );

      final expected = format(r'''
        test() {
          body
              .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
              .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
              .join('&');
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });
  });
}
