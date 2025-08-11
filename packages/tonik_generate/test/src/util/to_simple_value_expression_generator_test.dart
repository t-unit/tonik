import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

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
        buildToSimplePathParameterExpression('userId', parameter),
        'userId.toSimple(explode: false, allowEmpty: true)',
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
        buildToSimplePathParameterExpression(
          'id',
          parameter,
          explode: true,
          allowEmpty: false,
        ),
        'id.toSimple(explode: true, allowEmpty: false)',
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
        buildToSimplePathParameterExpression('timestamp', parameter),
        'timestamp.toSimple(explode: false, allowEmpty: true)',
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
        buildToSimpleHeaderParameterExpression('authorization', parameter),
        'authorization.toSimple(explode: false, allowEmpty: true)',
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
        buildToSimpleHeaderParameterExpression(
          'ifModifiedSince',
          parameter,
          explode: true,
          allowEmpty: false,
        ),
        'ifModifiedSince.toSimple(explode: true, allowEmpty: false)',
      );
    });
  });
}
