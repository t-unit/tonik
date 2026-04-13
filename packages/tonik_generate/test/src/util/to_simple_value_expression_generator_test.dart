import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

void main() {
  late Context context;
  late DartEmitter emitter;
  late DartEmitter scopedEmitter;

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
          "throw  _i1.EncodingException("
          "'Nested lists are not supported"
          " for simple encoding.')",
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
          "throw  _i1.EncodingException("
          "'Unsupported model type for simple encoding.')",
        );
      });

      test('generates runtime throw for List with MapModel content', () {
        final model = ListModel(
          content: MapModel(
            valueModel: StringModel(context: context),
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
          "throw  _i1.EncodingException("
          "'Unsupported content model for simple encoding.')",
        );
      });
    });
  });
}
