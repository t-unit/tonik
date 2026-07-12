import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/to_deep_object_query_parameter_expression_generator.dart';

void main() {
  group('buildToDeepObjectQueryParameterCode', () {
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

    String methodBody(BuiltExpression built) {
      final method = Method(
        (b) => b
          ..name = 'test'
          ..body = declareFinal('result').assign(built.expression).statement,
      );
      return format(method.accept(emitter).toString());
    }

    QueryParameterObject createParameter({
      required String name,
      required String rawName,
      required Model model,
      required bool explode,
      required bool allowEmpty,
      bool allowReserved = false,
    }) {
      return QueryParameterObject(
        name: name,
        rawName: rawName,
        description: null,
        model: model,
        isRequired: true,
        isDeprecated: false,
        encoding: QueryParameterEncoding.deepObject,
        explode: explode,
        allowEmptyValue: allowEmpty,
        allowReserved: allowReserved,
        context: context,
        examples: const [],
        defaultValue: null,
      );
    }

    test('generates code for class model', () {
      final parameter = createParameter(
        name: 'user',
        rawName: 'user',
        model: ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: context,
          examples: const [],
        ),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'user',
        parameter,
      );

      final code = result.accept(emitter).toString();
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          "user.toDeepObject(r'user', explode: true, allowEmpty: false, )",
        ),
      );
    });

    test('generates code for class model with explode false', () {
      final parameter = createParameter(
        name: 'user',
        rawName: 'user',
        model: ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: context,
          examples: const [],
        ),
        explode: false,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'user',
        parameter,
      );

      final code = result.accept(emitter).toString();
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          "user.toDeepObject(r'user', explode: false, allowEmpty: false, )",
        ),
      );
    });

    test('generates code for class model with allowEmpty true', () {
      final parameter = createParameter(
        name: 'user',
        rawName: 'user',
        model: ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: context,
          examples: const [],
        ),
        explode: true,
        allowEmpty: true,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'user',
        parameter,
      );

      final code = result.accept(emitter).toString();
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          "user.toDeepObject(r'user', explode: true, allowEmpty: true, )",
        ),
      );
    });

    test('generates code for allOf model', () {
      final parameter = createParameter(
        name: 'combined',
        rawName: 'combined',
        model: AllOfModel(
          isDeprecated: false,
          name: 'Combined',
          models: const {},
          context: context,
          examples: const [],
        ),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'combined',
        parameter,
      );

      final code = result.accept(emitter).toString();
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          'combined.toDeepObject('
          "r'combined', explode: true, allowEmpty: false, )",
        ),
      );
    });

    test('generates code for oneOf model', () {
      final parameter = createParameter(
        name: 'variant',
        rawName: 'variant',
        model: OneOfModel(
          isDeprecated: false,
          name: 'Variant',
          models: const {},
          context: context,
          examples: const [],
        ),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'variant',
        parameter,
      );

      final code = result.accept(emitter).toString();
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          'variant.toDeepObject('
          "r'variant', explode: true, allowEmpty: false, )",
        ),
      );
    });

    test('generates code for anyOf model', () {
      final parameter = createParameter(
        name: 'flexible',
        rawName: 'flexible',
        model: AnyOfModel(
          isDeprecated: false,
          name: 'Flexible',
          models: const {},
          context: context,
          examples: const [],
        ),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'flexible',
        parameter,
      );

      final code = result.accept(emitter).toString();
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          'flexible.toDeepObject('
          "r'flexible', explode: true, allowEmpty: false, )",
        ),
      );
    });

    test('generates code for alias model wrapping class', () {
      final parameter = createParameter(
        name: 'aliased',
        rawName: 'aliased',
        model: AliasModel(
          name: 'UserAlias',
          model: ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'aliased',
        parameter,
      );

      final code = result.accept(emitter).toString();
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          'aliased.toDeepObject('
          "r'aliased', explode: true, allowEmpty: false, )",
        ),
      );
    });

    test('generates runtime throw for primitive model', () {
      final parameter = createParameter(
        name: 'count',
        rawName: 'count',
        model: IntegerModel(context: context),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'count',
        parameter,
      );
      final code = result.accept(scopedEmitter).toString();

      expect(
        code,
        '''throw  _i1.EncodingException(r'deepObject encoding only supports object types. Parameter "count" is not supported.')''',
      );
    });

    test('generates runtime throw for list model', () {
      final parameter = createParameter(
        name: 'items',
        rawName: 'items',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'items',
        parameter,
      );
      final code = result.accept(scopedEmitter).toString();

      expect(
        code,
        '''throw  _i1.EncodingException(r'deepObject encoding only supports object types. Parameter "items" is not supported.')''',
      );
    });

    test('generates runtime throw for enum model', () {
      final parameter = createParameter(
        name: 'status',
        rawName: 'status',
        model: EnumModel(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: false,
          context: context,
          examples: const [],
        ),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'status',
        parameter,
      );
      final code = result.accept(scopedEmitter).toString();

      expect(
        code,
        '''throw  _i1.EncodingException(r'deepObject encoding only supports object types. Parameter "status" is not supported.')''',
      );
    });

    test('generates code with special characters in parameter name', () {
      final parameter = createParameter(
        name: 'userData',
        rawName: 'user-data',
        model: ClassModel(
          isDeprecated: false,
          name: 'UserData',
          properties: const [],
          context: context,
          examples: const [],
        ),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'userData',
        parameter,
      );

      final code = result.accept(emitter).toString();
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          'userData.toDeepObject('
          "r'user-data', explode: true, allowEmpty: false, )",
        ),
      );
    });

    test('generates encodeAnyToDeepObject call for AnyModel', () {
      final parameter = createParameter(
        name: 'data',
        rawName: 'data',
        model: AnyModel(context: context),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode(
        'data',
        parameter,
      );

      final code = result.accept(emitter).toString();
      expect(
        collapseWhitespace(code),
        collapseWhitespace(
          "encodeAnyToDeepObject(data, r'data', "
          'explode: true, allowEmpty: false, )',
        ),
      );
    });

    group('MapModel', () {
      test('generates direct toDeepObject for Map<String, String>', () {
        final parameter = createParameter(
          name: 'filter',
          rawName: 'filter',
          model: MapModel(
            valueModel: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'filter',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = filter
                  .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                  .toDeepObject(
                    r'filter',
                    explode: true,
                    allowEmpty: false,
                  );
            }
          ''')),
        );
      });

      test('generates direct toDeepObject for Map<String, String> '
          'with allowEmpty', () {
        final parameter = createParameter(
          name: 'filter',
          rawName: 'filter',
          model: MapModel(
            valueModel: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: true,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'filter',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = filter
                  .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                  .toDeepObject(
                    r'filter',
                    explode: true,
                    allowEmpty: true,
                  );
            }
          ''')),
        );
      });

      test('generates map + toDeepObject for Map<String, int>', () {
        final parameter = createParameter(
          name: 'counts',
          rawName: 'counts',
          model: MapModel(
            valueModel: IntegerModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'counts',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = counts
                  .map(
                    (k, v) => MapEntry(k, PropertyValue.scalar(v.toString())),
                  )
                  .toDeepObject(
                    r'counts',
                    explode: true,
                    allowEmpty: false,
                  );
            }
          ''')),
        );
      });

      test('generates map + toDeepObject for Map<String, bool>', () {
        final parameter = createParameter(
          name: 'flags',
          rawName: 'flags',
          model: MapModel(
            valueModel: BooleanModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'flags',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = flags
                  .map(
                    (k, v) => MapEntry(k, PropertyValue.scalar(v.toString())),
                  )
                  .toDeepObject(
                    r'flags',
                    explode: true,
                    allowEmpty: false,
                  );
            }
          ''')),
        );
      });

      test('generates map + toDeepObject for Map<String, Enum>', () {
        final parameter = createParameter(
          name: 'statuses',
          rawName: 'statuses',
          model: MapModel(
            valueModel: EnumModel(
              isDeprecated: false,
              name: 'Status',
              values: {
                const EnumEntry(value: 'active'),
                const EnumEntry(value: 'inactive'),
              },
              isNullable: false,
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'statuses',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = statuses
                  .map(
                    (k, v) => MapEntry(k, PropertyValue.scalar(v.toJson())),
                  )
                  .toDeepObject(
                    r'statuses',
                    explode: true,
                    allowEmpty: false,
                  );
            }
          ''')),
        );
      });

      test('generates map + toDeepObject for Map<String, AnyModel>', () {
        final parameter = createParameter(
          name: 'meta',
          rawName: 'meta',
          model: MapModel(
            valueModel: AnyModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'meta',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = Map.fromEntries(
                meta.entries
                    .where((e) => e.value != null)
                    .map(
                      (e) => MapEntry(
                        e.key,
                        PropertyValue.scalar(
                          encodeUnknownFlatScalar(
                            e.value!,
                            context: r'meta',
                          ),
                        ),
                      ),
                    ),
              ).toDeepObject(
                r'meta',
                explode: true,
                allowEmpty: false,
              );
            }
          ''')),
        );
      });

      test('generates throw for Map with complex value type', () {
        final parameter = createParameter(
          name: 'nested',
          rawName: 'nested',
          model: MapModel(
            valueModel: ClassModel(
              isDeprecated: false,
              name: 'Inner',
              properties: const [],
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'nested',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = throw EncodingException(
                r'deepObject encoding is not supported for Map types with complex values. Parameter "nested" cannot be encoded.',
              );
            }
          ''')),
        );
      });

      test('generates throw for Map with list value type', () {
        final parameter = createParameter(
          name: 'tags',
          rawName: 'tags',
          model: MapModel(
            valueModel: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'tags',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = throw EncodingException(
                r'deepObject encoding is not supported for Map types with complex values. Parameter "tags" cannot be encoded.',
              );
            }
          ''')),
        );
      });

      test('handles alias wrapping MapModel with string values', () {
        final parameter = createParameter(
          name: 'aliasedMap',
          rawName: 'aliased_map',
          model: AliasModel(
            name: 'FilterMap',
            model: MapModel(
              valueModel: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'aliasedMap',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = aliasedMap
                  .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                  .toDeepObject(
                    r'aliased_map',
                    explode: true,
                    allowEmpty: false,
                  );
            }
          ''')),
        );
      });

      test('handles alias wrapping MapModel with int values', () {
        final parameter = createParameter(
          name: 'aliasedCounts',
          rawName: 'aliased_counts',
          model: AliasModel(
            name: 'CountMap',
            model: MapModel(
              valueModel: IntegerModel(context: context),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'aliasedCounts',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = aliasedCounts
                  .map(
                    (k, v) => MapEntry(k, PropertyValue.scalar(v.toString())),
                  )
                  .toDeepObject(
                    r'aliased_counts',
                    explode: true,
                    allowEmpty: false,
                  );
            }
          ''')),
        );
      });
    });

    group('allowReserved', () {
      test('Map<String, String> carries allowReserved when set', () {
        final parameter = createParameter(
          name: 'filter',
          rawName: 'filter',
          model: MapModel(
            valueModel: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
          allowReserved: true,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'filter',
          parameter,
          allowReserved: true,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = filter
                  .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                  .toDeepObject(
                    r'filter',
                    explode: true,
                    allowEmpty: false,
                    allowReserved: true,
                  );
            }
          ''')),
        );
      });

      test('Map<String, String> omits allowReserved by default', () {
        final parameter = createParameter(
          name: 'filter',
          rawName: 'filter',
          model: MapModel(
            valueModel: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'filter',
          parameter,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = filter
                  .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                  .toDeepObject(
                    r'filter',
                    explode: true,
                    allowEmpty: false,
                  );
            }
          ''')),
        );
      });

      test('Map<String, int> threads allowReserved into value encode', () {
        final parameter = createParameter(
          name: 'counts',
          rawName: 'counts',
          model: MapModel(
            valueModel: IntegerModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
          allowReserved: true,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'counts',
          parameter,
          allowReserved: true,
        );

        final code = methodBody(result);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(format('''
            test() {
              final result = counts
                  .map(
                    (k, v) => MapEntry(k, PropertyValue.scalar(v.toString())),
                  )
                  .toDeepObject(
                    r'counts',
                    explode: true,
                    allowEmpty: false,
                    allowReserved: true,
                  );
            }
          ''')),
        );
      });

      test('AnyModel carries allowReserved when set', () {
        final parameter = createParameter(
          name: 'data',
          rawName: 'data',
          model: AnyModel(context: context),
          explode: true,
          allowEmpty: false,
          allowReserved: true,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'data',
          parameter,
          allowReserved: true,
        );

        final code = result.accept(emitter).toString();
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            "encodeAnyToDeepObject(data, r'data', "
            'explode: true, allowEmpty: false, allowReserved: true, )',
          ),
        );
      });

      test('AnyModel omits allowReserved by default', () {
        final parameter = createParameter(
          name: 'data',
          rawName: 'data',
          model: AnyModel(context: context),
          explode: true,
          allowEmpty: false,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'data',
          parameter,
        );

        final code = result.accept(emitter).toString();
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            "encodeAnyToDeepObject(data, r'data', "
            'explode: true, allowEmpty: false, )',
          ),
        );
      });

      test('class model object path threads allowReserved into toDeepObject '
          'when set', () {
        final parameter = createParameter(
          name: 'user',
          rawName: 'user',
          model: ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: false,
          allowReserved: true,
        );

        final result = buildToDeepObjectQueryParameterCode(
          'user',
          parameter,
          allowReserved: true,
        );

        final code = result.accept(emitter).toString();
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            "user.toDeepObject(r'user', explode: true, allowEmpty: false, "
            'allowReserved: true, )',
          ),
        );
      });
    });
  });
}
