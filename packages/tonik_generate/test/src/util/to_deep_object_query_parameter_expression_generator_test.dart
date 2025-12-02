import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_deep_object_query_parameter_expression_generator.dart';

String collapseWhitespace(String input) {
  return input.replaceAll(RegExp(r'\s+'), ' ').trim();
}

void main() {
  group('buildToDeepObjectQueryParameterCode', () {
    late Context context;
    late DartEmitter emitter;

    setUp(() {
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    QueryParameterObject createParameter({
      required String name,
      required String rawName,
      required Model model,
      required bool explode,
      required bool allowEmpty,
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
        allowReserved: false,
        context: context,
      );
    }

    test('generates code for class model', () {
      final parameter = createParameter(
        name: 'user',
        rawName: 'user',
        model: ClassModel(
          name: 'User',
          properties: const [],
          context: context,
          description: null,
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
          name: 'User',
          properties: const [],
          context: context,
          description: null,
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
          name: 'User',
          properties: const [],
          context: context,
          description: null,
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
          name: 'Combined',
          models: const {},
          context: context,
          description: null,
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
          name: 'Variant',
          models: const {},
          discriminator: null,
          context: context,
          description: null,
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
          name: 'Flexible',
          models: const {},
          discriminator: null,
          context: context,
          description: null,
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
            name: 'User',
            properties: const [],
            context: context,
            description: null,
          ),
          context: context,
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

      final result = buildToDeepObjectQueryParameterCode('count', parameter);
      final code = result.accept(emitter).toString();

      expect(
        collapseWhitespace(code),
        contains('throw EncodingException('),
      );
      expect(
        collapseWhitespace(code),
        contains('deepObject encoding only supports object types'),
      );
      expect(
        collapseWhitespace(code),
        contains('count'),
      );
    });

    test('generates runtime throw for list model', () {
      final parameter = createParameter(
        name: 'items',
        rawName: 'items',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode('items', parameter);
      final code = result.accept(emitter).toString();

      expect(
        collapseWhitespace(code),
        contains('throw EncodingException('),
      );
      expect(
        collapseWhitespace(code),
        contains('deepObject encoding only supports object types'),
      );
      expect(
        collapseWhitespace(code),
        contains('items'),
      );
    });

    test('generates runtime throw for enum model', () {
      final parameter = createParameter(
        name: 'status',
        rawName: 'status',
        model: EnumModel(
          name: 'Status',
          values: const {'active', 'inactive'},
          isNullable: false,
          context: context,
          description: null,
        ),
        explode: true,
        allowEmpty: false,
      );

      final result = buildToDeepObjectQueryParameterCode('status', parameter);
      final code = result.accept(emitter).toString();

      expect(
        collapseWhitespace(code),
        contains('throw EncodingException('),
      );
      expect(
        collapseWhitespace(code),
        contains('deepObject encoding only supports object types'),
      );
      expect(
        collapseWhitespace(code),
        contains('status'),
      );
    });

    test('generates code with special characters in parameter name', () {
      final parameter = createParameter(
        name: 'userData',
        rawName: 'user-data',
        model: ClassModel(
          name: 'UserData',
          properties: const [],
          context: context,
          description: null,
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
  });
}
