import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_label_path_parameter_expression_generator.dart';

void main() {
  late Context context;
  late DartEmitter emitter;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  String emit(Expression expr) => expr.accept(emitter).toString();

  group('buildToLabelPathParameterExpression', () {
    test('generates toLabel expression for primitive path parameter', () {
      final parameter = PathParameterObject(
        name: 'userId',
        rawName: 'userId',
        description: 'User ID parameter',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToLabelPathParameterExpression('userId', parameter)),
        'userId.toLabel(explode: false, allowEmpty: false, )',
      );
    });

    test(
      'generates toLabel expression for array path parameter with '
      'explode=false',
      () {
        final parameter = PathParameterObject(
          name: 'ids',
          rawName: 'ids',
          description: 'User IDs parameter',
          model: ListModel(
            context: context,
            content: StringModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('ids', parameter)),
          'ids.toLabel(explode: false, allowEmpty: false, )',
        );
      },
    );

    test(
      'generates toLabel expression for array path parameter with explode=true',
      () {
        final parameter = PathParameterObject(
          name: 'ids',
          rawName: 'ids',
          description: 'User IDs parameter',
          model: ListModel(
            context: context,
            content: StringModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: true,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('ids', parameter)),
          'ids.toLabel(explode: true, allowEmpty: false, )',
        );
      },
    );

    test('generates toLabel expression for optional path parameter', () {
      final parameter = PathParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Optional filter parameter',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: true,
        isRequired: false,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToLabelPathParameterExpression('filter', parameter)),
        'filter.toLabel(explode: false, allowEmpty: true, )',
      );
    });

    test('generates toLabel expression for enum path parameter', () {
      final parameter = PathParameterObject(
        name: 'status',
        rawName: 'status',
        description: 'Status parameter',
        model: EnumModel(
          isDeprecated: false,
          context: context,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: false,
        ),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToLabelPathParameterExpression('status', parameter)),
        'status.toLabel(explode: false, allowEmpty: false, )',
      );
    });

    test('generates toLabel expression for integer path parameter', () {
      final parameter = PathParameterObject(
        name: 'id',
        rawName: 'id',
        description: 'ID parameter',
        model: IntegerModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToLabelPathParameterExpression('id', parameter)),
        'id.toLabel(explode: false, allowEmpty: false, )',
      );
    });

    test('generates toLabel expression for double path parameter', () {
      final parameter = PathParameterObject(
        name: 'price',
        rawName: 'price',
        description: 'Price parameter',
        model: DoubleModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToLabelPathParameterExpression('price', parameter)),
        'price.toLabel(explode: false, allowEmpty: false, )',
      );
    });

    test('generates toLabel expression for boolean path parameter', () {
      final parameter = PathParameterObject(
        name: 'enabled',
        rawName: 'enabled',
        description: 'Enabled parameter',
        model: BooleanModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToLabelPathParameterExpression('enabled', parameter)),
        'enabled.toLabel(explode: false, allowEmpty: false, )',
      );
    });

    test('generates toLabel expression for DateTime path parameter', () {
      final parameter = PathParameterObject(
        name: 'timestamp',
        rawName: 'timestamp',
        description: 'Timestamp parameter',
        model: DateTimeModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToLabelPathParameterExpression('timestamp', parameter)),
        'timestamp.toLabel(explode: false, allowEmpty: false, )',
      );
    });

    test('generates toLabel expression for class path parameter', () {
      final parameter = PathParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Filter parameter',
        model: ClassModel(
          isDeprecated: false,
          context: context,
          name: 'Filter',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'value',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        ),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToLabelPathParameterExpression('filter', parameter)),
        'filter.toLabel(explode: false, allowEmpty: false, )',
      );
    });

    test(
      'generates toLabel expression with custom explode and allowEmpty '
      'parameters',
      () {
        final explodeTrueParameter = PathParameterObject(
          name: 'ids',
          rawName: 'ids',
          description: 'User IDs parameter',
          model: ListModel(
            context: context,
            content: StringModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: true,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(
            buildToLabelPathParameterExpression(
              'ids',
              explodeTrueParameter,
            ),
          ),
          'ids.toLabel(explode: true, allowEmpty: false, )',
        );
      },
    );

    test(
      'generates toLabel expression for array of enums '
      '(maps to uriEncode first)',
      () {
        final parameter = PathParameterObject(
          name: 'statuses',
          rawName: 'statuses',
          description: 'Status values parameter',
          model: ListModel(
            context: context,
            content: EnumModel(
              isDeprecated: false,
              context: context,
              name: 'Status',
              values: {
                const EnumEntry(value: 'active'),
                const EnumEntry(value: 'inactive'),
                const EnumEntry(value: 'pending'),
              },
              isNullable: false,
            ),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('statuses', parameter)),
          '''statuses.map((e) => e.uriEncode(allowEmpty: false)).toList().toLabel(explode: false, allowEmpty: false, alreadyEncoded: true, )''',
        );
      },
    );

    test(
      'generates toLabel expression for array of integers '
      '(maps to uriEncode first)',
      () {
        final parameter = PathParameterObject(
          name: 'ids',
          rawName: 'ids',
          description: 'Integer IDs parameter',
          model: ListModel(
            context: context,
            content: IntegerModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('ids', parameter)),
          '''ids.map((e) => e.uriEncode(allowEmpty: false)).toList().toLabel(explode: false, allowEmpty: false, alreadyEncoded: true, )''',
        );
      },
    );

    test(
      'generates toLabel expression for optional array of enums',
      () {
        final parameter = PathParameterObject(
          name: 'statuses',
          rawName: 'statuses',
          description: 'Optional status values parameter',
          model: ListModel(
            context: context,
            content: EnumModel(
              isDeprecated: false,
              context: context,
              name: 'Status',
              values: {
                const EnumEntry(value: 'active'),
                const EnumEntry(value: 'inactive'),
                const EnumEntry(value: 'pending'),
              },
              isNullable: false,
            ),
          ),
          encoding: PathParameterEncoding.label,
          explode: true,
          allowEmptyValue: true,
          isRequired: false,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('statuses', parameter)),
          '''statuses.map((e) => e.uriEncode(allowEmpty: true)).toList().toLabel(explode: true, allowEmpty: true, alreadyEncoded: true, )''',
        );
      },
    );

    test(
      'generates toLabel expression for array of doubles '
      '(maps to uriEncode first)',
      () {
        final parameter = PathParameterObject(
          name: 'prices',
          rawName: 'prices',
          description: 'Price values parameter',
          model: ListModel(
            context: context,
            content: DoubleModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('prices', parameter)),
          '''prices.map((e) => e.uriEncode(allowEmpty: false)).toList().toLabel(explode: false, allowEmpty: false, alreadyEncoded: true, )''',
        );
      },
    );

    test(
      'generates toLabel expression for array of booleans '
      '(maps to uriEncode first)',
      () {
        final parameter = PathParameterObject(
          name: 'flags',
          rawName: 'flags',
          description: 'Boolean flags parameter',
          model: ListModel(
            context: context,
            content: BooleanModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('flags', parameter)),
          '''flags.map((e) => e.uriEncode(allowEmpty: false)).toList().toLabel(explode: false, allowEmpty: false, alreadyEncoded: true, )''',
        );
      },
    );

    test(
      'generates toLabel expression for array of DateTimes '
      '(maps to uriEncode first)',
      () {
        final parameter = PathParameterObject(
          name: 'timestamps',
          rawName: 'timestamps',
          description: 'Timestamp values parameter',
          model: ListModel(
            context: context,
            content: DateTimeModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('timestamps', parameter)),
          '''timestamps.map((e) => e.uriEncode(allowEmpty: false)).toList().toLabel(explode: false, allowEmpty: false, alreadyEncoded: true, )''',
        );
      },
    );

    test(
      'generates toLabel expression for array of OneOf '
      '(maps to encodeAnyToUri)',
      () {
        final parameter = PathParameterObject(
          name: 'values',
          rawName: 'values',
          description: 'OneOf values parameter',
          model: ListModel(
            context: context,
            content: OneOfModel(
              isDeprecated: false,
              context: context,
              name: 'StringOrInt',
              models: {
                (
                  discriminatorValue: 's',
                  model: StringModel(context: context),
                ),
                (
                  discriminatorValue: 'i',
                  model: IntegerModel(context: context),
                ),
              },
            ),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('values', parameter)),
          '''values.map((e) => encodeAnyToUri(e, allowEmpty: false, )).toList().toLabel(explode: false, allowEmpty: false, alreadyEncoded: true, )''',
        );
      },
    );

    test(
      'generates toLabel expression for array of AnyOf '
      '(maps to encodeAnyToUri)',
      () {
        final parameter = PathParameterObject(
          name: 'values',
          rawName: 'values',
          description: 'AnyOf values parameter',
          model: ListModel(
            context: context,
            content: AnyOfModel(
              isDeprecated: false,
              context: context,
              name: 'StringOrInt',
              models: {
                (
                  discriminatorValue: 's',
                  model: StringModel(context: context),
                ),
                (
                  discriminatorValue: 'i',
                  model: IntegerModel(context: context),
                ),
              },
            ),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('values', parameter)),
          '''values.map((e) => encodeAnyToUri(e, allowEmpty: false, )).toList().toLabel(explode: false, allowEmpty: false, alreadyEncoded: true, )''',
        );
      },
    );

    test(
      'generates toLabel expression for array of numbers '
      '(maps to uriEncode first)',
      () {
        final parameter = PathParameterObject(
          name: 'amounts',
          rawName: 'amounts',
          description: 'Number values parameter',
          model: ListModel(
            context: context,
            content: NumberModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('amounts', parameter)),
          '''amounts.map((e) => e.uriEncode(allowEmpty: false)).toList().toLabel(explode: false, allowEmpty: false, alreadyEncoded: true, )''',
        );
      },
    );

    test(
      'generates toLabel expression for array of AnyModel '
      '(maps to encodeAnyToUri)',
      () {
        final parameter = PathParameterObject(
          name: 'anyValues',
          rawName: 'anyValues',
          description: 'Any values parameter',
          model: ListModel(
            context: context,
            content: AnyModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('anyValues', parameter)),
          '''anyValues.map((e) => encodeAnyToUri(e, allowEmpty: false, )).toList().toLabel(explode: false, allowEmpty: false, alreadyEncoded: true, )''',
        );
      },
    );
  });

  group('MapModel direct support', () {
    test('generates label encoding for MapModel with StringModel values', () {
      final parameter = PathParameterObject(
        name: 'tags',
        rawName: 'tags',
        description: 'Tags parameter',
        model: MapModel(
          valueModel: StringModel(context: context),
          context: context,
        ),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToLabelPathParameterExpression('tags', parameter)),
        'tags.toLabel(explode: false, allowEmpty: false, )',
      );
    });

    test(
      'generates label encoding for MapModel with IntegerModel values',
      () {
        final parameter = PathParameterObject(
          name: 'counts',
          rawName: 'counts',
          description: 'Counts parameter',
          model: MapModel(
            valueModel: IntegerModel(context: context),
            context: context,
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        final result =
            emit(buildToLabelPathParameterExpression('counts', parameter));
        expect(
          collapseWhitespace(result),
          collapseWhitespace([
            'counts.map((k, v, ) => MapEntry(k, v.toString(), ))',
            '.toLabel(explode: false, allowEmpty: false, )',
          ].join()),
        );
      },
    );

    test(
      'throws for MapModel with ClassModel values',
      () {
        final parameter = PathParameterObject(
          name: 'data',
          rawName: 'data',
          description: 'Data parameter',
          model: MapModel(
            valueModel: ClassModel(
              isDeprecated: false,
              context: context,
              name: 'Obj',
              properties: [],
            ),
            context: context,
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          collapseWhitespace(
            emit(buildToLabelPathParameterExpression('data', parameter)),
          ),
          collapseWhitespace([
            'throw EncodingException(',
            "'Map with complex value types cannot be label-encoded.')",
          ].join()),
        );
      },
    );
  });

  group('Base64Model direct support', () {
    test('generates toBase64String then toLabel for Base64Model', () {
      final parameter = PathParameterObject(
        name: 'fileData',
        rawName: 'fileData',
        description: 'Base64 file parameter',
        model: Base64Model(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      final result =
          emit(buildToLabelPathParameterExpression('fileData', parameter));
      expect(
        collapseWhitespace(result),
        collapseWhitespace([
          'fileData.toBase64String()',
          '.toLabel(explode: false, allowEmpty: false, )',
        ].join()),
      );
    });
  });

  group('unsupported types generate throw', () {
    test('List of ClassModel throws EncodingException', () {
      final parameter = PathParameterObject(
        name: 'itemList',
        rawName: 'itemList',
        description: 'List of objects parameter',
        model: ListModel(
          context: context,
          content: ClassModel(
            isDeprecated: false,
            context: context,
            name: 'Item',
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
          ),
        ),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        collapseWhitespace(
          emit(buildToLabelPathParameterExpression('itemList', parameter)),
        ),
        collapseWhitespace([
          'throw EncodingException(',
          "'Label encoding does not support ",
          "arrays of complex types')",
        ].join()),
      );
    });

    test(
      'List of MapModel with IntegerModel values generates '
      'label encoding',
      () {
        final parameter = PathParameterObject(
          name: 'items',
          rawName: 'items',
          description: 'List of maps parameter',
          model: ListModel(
            context: context,
            content: MapModel(
              valueModel: IntegerModel(context: context),
              context: context,
            ),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        final result =
            emit(buildToLabelPathParameterExpression('items', parameter));
        expect(
          collapseWhitespace(result),
          collapseWhitespace([
            'items.map((e) => e.map((k, v, ) ',
            '=> MapEntry(k, v.toString(), ))',
            '.toLabel(explode: false, allowEmpty: false, ))',
            '.toList()',
            '.toLabel(explode: false, ',
            'allowEmpty: false, alreadyEncoded: true, )',
          ].join()),
        );
      },
    );

    test(
      'List of MapModel with ClassModel values throws EncodingException',
      () {
        final parameter = PathParameterObject(
          name: 'items',
          rawName: 'items',
          description: 'List of maps parameter',
          model: ListModel(
            context: context,
            content: MapModel(
              valueModel: ClassModel(
                isDeprecated: false,
                context: context,
                name: 'Obj',
                properties: [],
              ),
              context: context,
            ),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          collapseWhitespace(
            emit(buildToLabelPathParameterExpression('items', parameter)),
          ),
          collapseWhitespace([
            'throw EncodingException(',
            "'Label encoding does not support ",
            "arrays of maps with complex values')",
          ].join()),
        );
      },
    );

    test('List of Base64Model generates label encoding', () {
      final parameter = PathParameterObject(
        name: 'files',
        rawName: 'files',
        description: 'List of base64 files',
        model: ListModel(
          context: context,
          content: Base64Model(context: context),
        ),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      final result =
          emit(buildToLabelPathParameterExpression('files', parameter));
      expect(
        collapseWhitespace(result),
        collapseWhitespace([
          'files.map((e) => e.toBase64String()).toList()',
          '.toLabel(explode: false, ',
          'allowEmpty: false, alreadyEncoded: true, )',
        ].join()),
      );
    });
  });

  group('nullable model support', () {
    test(
      'uses null assertion for nullable AliasModel '
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
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(
            buildToLabelPathParameterExpression('loaDocumentId', parameter),
          ),
          'loaDocumentId!.toLabel(explode: false, allowEmpty: false, )',
        );
      },
    );

    test('uses non-null toLabel for non-nullable model', () {
      final parameter = PathParameterObject(
        name: 'userId',
        rawName: 'userId',
        description: 'User ID',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        emit(buildToLabelPathParameterExpression('userId', parameter)),
        'userId.toLabel(explode: false, allowEmpty: false, )',
      );
    });

    test(
      'uses null assertion for nullable ListModel<String> '
      'since path params are required',
      () {
        final parameter = PathParameterObject(
          name: 'tags',
          rawName: 'tags',
          description: 'Tags parameter',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            isNullable: true,
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          emit(buildToLabelPathParameterExpression('tags', parameter)),
          'tags!.toLabel(explode: false, allowEmpty: false, )',
        );
      },
    );
  });
}
