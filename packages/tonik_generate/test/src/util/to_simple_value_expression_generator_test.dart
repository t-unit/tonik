import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

void main() {
  late Context context;
  late DartEmitter emitter;
  late DartEmitter scopedEmitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
    scopedEmitter = DartEmitter(
      useNullSafetySyntax: true,
      allocator: CorePrefixedAllocator(),
    );
  });

  String emit(Expression expr) => expr.accept(emitter).toString();

  group('buildToSimplePathParameterExpression', () {
    test('for String parameter', () {
      final parameter = PathParameterObject(
        name: 'userId',
        rawName: 'userId',
        description: 'User ID parameter',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToSimplePathParameterExpression('userId', parameter)),
        'userId.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('for Integer parameter with custom params', () {
      final parameter = PathParameterObject(
        name: 'id',
        rawName: 'id',
        description: 'ID parameter',
        model: IntegerModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(
          buildToSimplePathParameterExpression(
            'id',
            parameter,
            explode: true,
            allowEmpty: false,
          ),
        ),
        'id.toSimple(explode: true, allowEmpty: false, )',
      );
    });

    test('for DateTime parameter', () {
      final parameter = PathParameterObject(
        name: 'timestamp',
        rawName: 'timestamp',
        description: 'Timestamp parameter',
        model: DateTimeModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToSimplePathParameterExpression('timestamp', parameter)),
        'timestamp.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('for NeverModel parameter throws EncodingException', () {
      final parameter = PathParameterObject(
        name: 'neverParam',
        rawName: 'neverParam',
        description: 'Never parameter',
        model: NeverModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToSimplePathParameterExpression('neverParam', parameter)),
        '''throw  EncodingException('Cannot encode NeverModel - this type does not permit any value.')''',
      );
    });
  });

  group('buildToSimpleHeaderParameterExpression', () {
    test('for String header', () {
      final parameter = RequestHeaderObject(
        name: 'authorization',
        rawName: 'Authorization',
        description: 'Authorization header',
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(
          buildToSimpleHeaderParameterExpression('authorization', parameter),
        ),
        'authorization.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('for DateTime header with custom params', () {
      final parameter = RequestHeaderObject(
        name: 'ifModifiedSince',
        rawName: 'If-Modified-Since',
        description: 'If-Modified-Since header',
        model: DateTimeModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(
          buildToSimpleHeaderParameterExpression(
            'ifModifiedSince',
            parameter,
            explode: true,
            allowEmpty: false,
          ),
        ),
        'ifModifiedSince.toSimple(explode: true, allowEmpty: false, )',
      );
    });

    test('for NeverModel header throws EncodingException', () {
      final parameter = RequestHeaderObject(
        name: 'neverHeader',
        rawName: 'NeverHeader',
        description: 'Never header',
        model: NeverModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(
          buildToSimpleHeaderParameterExpression('neverHeader', parameter),
        ),
        '''throw  EncodingException('Cannot encode NeverModel - this type does not permit any value.')''',
      );
    });
  });

  group('buildSimpleValueExpression', () {
    test('serializes string model', () {
      final model = StringModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('myParam'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'myParam.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes integer model', () {
      final model = IntegerModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('count'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'count.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes boolean model', () {
      final model = BooleanModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('flag'),
            model,
            explode: true,
            allowEmpty: false,
          ),
        ),
        'flag.toSimple(explode: true, allowEmpty: false, )',
      );
    });

    test('serializes enum model', () {
      final model = EnumModel<String>(
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(
          buildSimpleValueExpression(
            refer('status'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'status.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes dateTime model', () {
      final model = DateTimeModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('timestamp'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'timestamp.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes never model as exception', () {
      final model = NeverModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('neverParam'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        '''throw  EncodingException('Cannot encode NeverModel - this type does not permit any value.')''',
      );
    });

    test('respects isNullable flag', () {
      final model = StringModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('myParam'),
            model,
            explode: false,
            allowEmpty: true,
            isNullable: true,
          ),
        ),
        'myParam?.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes list of strings', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      expect(
        emit(
          buildSimpleValueExpression(
            refer('tags'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'tags.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes alias model by resolving underlying type', () {
      final underlying = IntegerModel(context: context);
      final model = AliasModel(
        name: 'MyInt',
        model: underlying,
        context: context,
      );
      expect(
        emit(
          buildSimpleValueExpression(
            refer('myInt'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'myInt.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    group('unsupported model types generate runtime throws', () {
      test('nested ListModel generates runtime throw', () {
        final model = ListModel(
          content: ListModel(
            content: StringModel(context: context),
            context: context,
          ),
          context: context,
        );
        expect(
          buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          ).accept(scopedEmitter).toString(),
          '''throw  _i1.EncodingException('Nested lists are not supported for simple encoding.')''',
        );
      });

      test('generates runtime throw for BinaryModel', () {
        expect(
          buildSimpleValueExpression(
            refer('value'),
            BinaryModel(context: context),
            explode: false,
            allowEmpty: true,
          ).accept(scopedEmitter).toString(),
          '''throw  _i1.EncodingException('Unsupported model type for simple encoding.')''',
        );
      });
    });

    group('MapModel', () {
      test('generates toSimple for MapModel with StringModel values', () {
        final model = MapModel(
          valueModel: StringModel(context: context),
          context: context,
        );
        final expression = buildSimpleValueExpression(
          refer('value'),
          model,
          explode: false,
          allowEmpty: true,
        );

        final generated = format(
          'final result = ${expression.accept(emitter)};',
        );
        const expected = '''
          final result = value.toSimple(explode: false, allowEmpty: true);
        ''';

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(format(expected)),
        );
      });

      test(
        'generates map and toSimple for MapModel with IntegerModel values',
        () {
          final model = MapModel(
            valueModel: IntegerModel(context: context),
            context: context,
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal('result').assign(expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map((k, v) => MapEntry(k, v.toString()))
                  .toSimple(explode: false, allowEmpty: true);
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates map and toSimple for MapModel with DateTimeModel values',
        () {
          final model = MapModel(
            valueModel: DateTimeModel(context: context),
            context: context,
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal('result').assign(expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map((k, v) => MapEntry(k, v.toTimeZonedIso8601String()))
                  .toSimple(explode: false, allowEmpty: true);
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates map and toSimple for MapModel with EnumModel values',
        () {
          final model = MapModel(
            valueModel: EnumModel<String>(
              isDeprecated: false,
              name: 'Status',
              values: {
                const EnumEntry(value: 'active'),
              },
              isNullable: false,
              context: context,
            ),
            context: context,
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal('result').assign(expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map((k, v) => MapEntry(k, v.toJson()))
                  .toSimple(explode: false, allowEmpty: true);
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates runtime throw for MapModel with ClassModel values',
        () {
          final model = MapModel(
            valueModel: ClassModel(
              isDeprecated: false,
              name: 'User',
              properties: [],
              context: context,
            ),
            context: context,
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal('result').assign(expression).statement,
          );

          final generated = format(method.accept(scopedEmitter).toString());
          final expected = format('''
            test() {
              final result = throw _i1.EncodingException(
                'Map with complex value types cannot be simple-encoded.',
              );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates null-safe toSimple for nullable MapModel '
        'with StringModel values',
        () {
          final model = MapModel(
            valueModel: StringModel(context: context),
            context: context,
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
            isNullable: true,
          );

          final generated = format(
            'final result = ${expression.accept(emitter)};',
          );
          const expected = '''
            final result = value?.toSimple(explode: false, allowEmpty: true);
          ''';

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(format(expected)),
          );
        },
      );
    });

    group('Base64Model', () {
      test('generates toBase64String and toSimple for Base64Model', () {
        final model = Base64Model(context: context);
        final expression = buildSimpleValueExpression(
          refer('value'),
          model,
          explode: false,
          allowEmpty: true,
        );

        final method = Method(
          (b) => b
            ..name = 'test'
            ..body = declareFinal('result').assign(expression).statement,
        );

        final generated = format(method.accept(emitter).toString());
        final expected = format('''
          test() {
            final result = value
                .toBase64String()
                .toSimple(explode: false, allowEmpty: true);
          }
        ''');

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(expected),
        );
      });

      test(
        'generates null-safe toBase64String for nullable Base64Model',
        () {
          final model = Base64Model(context: context);
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
            isNullable: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal('result').assign(expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  ?.toBase64String()
                  .toSimple(explode: false, allowEmpty: true);
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );
    });

    group('List<Base64Model>', () {
      test(
        'generates toBase64String list content for List<Base64Model>',
        () {
          final model = ListModel(
            content: Base64Model(context: context),
            context: context,
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal('result').assign(expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map((e) => e.toBase64String())
                  .toList()
                  .toSimple(
                    explode: false,
                    allowEmpty: true,
                    alreadyEncoded: true,
                  );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates null-safe map for nullable List<Base64Model>',
        () {
          final model = ListModel(
            content: Base64Model(context: context),
            context: context,
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
            isNullable: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal('result').assign(expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  ?.map((e) => e.toBase64String())
                  .toList()
                  .toSimple(
                    explode: false,
                    allowEmpty: true,
                    alreadyEncoded: true,
                  );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );
    });

    group('List<MapModel>', () {
      test(
        'generates list-of-map encoding for List<Map<String, String>>',
        () {
          final model = ListModel(
            content: MapModel(
              valueModel: StringModel(context: context),
              context: context,
            ),
            context: context,
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal('result').assign(expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map(
                    (e) => e.toSimple(explode: false, allowEmpty: true),
                  )
                  .toList()
                  .toSimple(
                    explode: false,
                    allowEmpty: true,
                    alreadyEncoded: true,
                  );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates list-of-map encoding for List<Map<String, int>>',
        () {
          final model = ListModel(
            content: MapModel(
              valueModel: IntegerModel(context: context),
              context: context,
            ),
            context: context,
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal('result').assign(expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map(
                    (e) => e
                        .map((k, v) => MapEntry(k, v.toString()))
                        .toSimple(explode: false, allowEmpty: true),
                  )
                  .toList()
                  .toSimple(
                    explode: false,
                    allowEmpty: true,
                    alreadyEncoded: true,
                  );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates runtime throw for List<Map<String, ClassModel>>',
        () {
          final model = ListModel(
            content: MapModel(
              valueModel: ClassModel(
                isDeprecated: false,
                name: 'User',
                properties: [],
                context: context,
              ),
              context: context,
            ),
            context: context,
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal('result').assign(expression).statement,
          );

          final generated = format(method.accept(scopedEmitter).toString());
          final expected = format('''
            test() {
              final result = throw _i1.EncodingException(
                'List of maps with complex value types cannot be simple-encoded.',
              );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );
    });
  });

  group('buildToSimplePathParameterExpression with nullable model', () {
    test(
      'uses null assertion for effectively nullable AliasModel '
      'since path params are required',
      () {
        final parameter = PathParameterObject(
          name: 'loaDocumentId',
          rawName: 'loa_document_id',
          description: 'LOA document ID',
          model: AliasModel(
            name: 'LoaDocumentIdentifier',
            model: StringModel(context: context),
            context: context,
            isNullable: true,
          ),
          encoding: PathParameterEncoding.simple,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(
            buildToSimplePathParameterExpression('loaDocumentId', parameter),
          ),
          'loaDocumentId!.toSimple(explode: false, allowEmpty: true, )',
        );
      },
    );

    test('uses non-null call for non-nullable model', () {
      final parameter = PathParameterObject(
        name: 'userId',
        rawName: 'userId',
        description: 'User ID',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(
          buildToSimplePathParameterExpression('userId', parameter),
        ),
        'userId.toSimple(explode: false, allowEmpty: true, )',
      );
    });
  });

  group('buildToSimpleHeaderParameterExpression with nullable model', () {
    test('uses null-safe call for effectively nullable AliasModel', () {
      final parameter = RequestHeaderObject(
        name: 'x-custom-header',
        rawName: 'x-custom-header',
        description: 'Custom header',
        model: AliasModel(
          name: 'HeaderAlias',
          model: StringModel(context: context),
          context: context,
          isNullable: true,
        ),
        encoding: HeaderParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(
          buildToSimpleHeaderParameterExpression('xCustomHeader', parameter),
        ),
        'xCustomHeader?.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test(
      'uses non-null call for effectively nullable AliasModel '
      'when isNullChecked is true',
      () {
        final parameter = RequestHeaderObject(
          name: 'x-custom-header',
          rawName: 'x-custom-header',
          description: 'Custom header',
          model: AliasModel(
            name: 'HeaderAlias',
            model: StringModel(context: context),
            context: context,
            isNullable: true,
          ),
          encoding: HeaderParameterEncoding.simple,
          explode: false,
          allowEmptyValue: false,
          isRequired: false,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(
            buildToSimpleHeaderParameterExpression(
              'xCustomHeader',
              parameter,
              isNullChecked: true,
            ),
          ),
          'xCustomHeader.toSimple(explode: false, allowEmpty: true, )',
        );
      },
    );

    test(
      'uses non-null call for nullable ClassModel '
      'when isNullChecked is true',
      () {
        final parameter = RequestHeaderObject(
          name: 'x-nullable-object',
          rawName: 'X-Nullable-Object',
          description: 'Nullable object header',
          model: ClassModel(
            name: 'NullableObj',
            properties: const [],
            context: context,
            isNullable: true,
            isDeprecated: false,
          ),
          encoding: HeaderParameterEncoding.simple,
          explode: false,
          allowEmptyValue: false,
          isRequired: false,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(
            buildToSimpleHeaderParameterExpression(
              'xNullableObject',
              parameter,
              isNullChecked: true,
            ),
          ),
          'xNullableObject.toSimple(explode: false, allowEmpty: true, )',
        );
      },
    );

    test(
      'uses null-safe call for nullable model when isNullChecked is false',
      () {
        final parameter = RequestHeaderObject(
          name: 'x-nullable-header',
          rawName: 'X-Nullable-Header',
          description: 'Nullable header',
          model: ClassModel(
            name: 'NullableObj',
            properties: const [],
            context: context,
            isNullable: true,
            isDeprecated: false,
          ),
          encoding: HeaderParameterEncoding.simple,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(
            buildToSimpleHeaderParameterExpression(
              'xNullableHeader',
              parameter,
            ),
          ),
          'xNullableHeader?.toSimple(explode: false, allowEmpty: true, )',
        );
      },
    );
  });
}
