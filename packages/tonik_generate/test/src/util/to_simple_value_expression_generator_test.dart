import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

void main() {
  late Context context;
  late DartEmitter emitter;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
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
}
