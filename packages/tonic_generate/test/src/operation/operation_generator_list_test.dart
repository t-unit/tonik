import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/operation/operation_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

void main() {
  group('OperationGenerator list handling', () {
    late OperationGenerator generator;
    late Context context;
    late DartEmitter emitter;
    late NameManager nameManager;
    late NameGenerator nameGenerator;

    final format =
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = OperationGenerator(
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    group('query parameters', () {
      test('handles simple list of enums', () {
        final enumModel = EnumModel(
          context: context,
          values: const {'RED', 'GREEN', 'BLUE'},
          isNullable: false,
        );

        final listModel = ListModel(context: context, content: enumModel);

        final queryParam = QueryParameterObject(
          name: 'colors',
          rawName: 'colors',
          description: 'List of colors',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: true,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: listModel,
          context: context,
        );

        final operation = Operation(
          operationId: 'listColors',
          context: context,
          summary: 'List colors',
          description: 'Lists all colors',
          tags: const {},
          isDeprecated: false,
          path: '/colors',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {queryParam},
          pathParameters: const {},
          responses: const {},
        );

        const expectedMethod = '''
          Map<String, dynamic> _queryParameters({required List<Anonymous> colors}) {
            final result = <String, dynamic>{};
            final formEncoder = FormEncoder();
            result[r'colors'] = formEncoder.encode(
              r'colors',
              colors.map((e) => e.toJson()).toList(),
              explode: true,
              allowEmpty: false,
            );
            return result;
          }
        ''';

        final queryParameters =
            <({String normalizedName, QueryParameterObject parameter})>[
              (normalizedName: 'colors', parameter: queryParam),
            ];

        final method = generator.generateQueryParametersMethod(
          operation,
          queryParameters,
        );

        expect(method, isA<Method>());
        expect(method.optionalParameters.first.named, isTrue);
        expect(method.optionalParameters.first.required, isTrue);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      });

      test('handles nested list of class models', () {
        final innerModel = ClassModel(context: context, properties: const {});
        final innerListModel = ListModel(context: context, content: innerModel);
        final outerListModel = ListModel(
          context: context,
          content: innerListModel,
        );

        final queryParam = QueryParameterObject(
          name: 'matrix',
          rawName: 'matrix',
          description: 'Matrix of items',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: true,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: outerListModel,
          context: context,
        );

        final operation = Operation(
          operationId: 'getMatrix',
          context: context,
          summary: 'Get matrix',
          description: 'Gets matrix data',
          tags: const {},
          isDeprecated: false,
          path: '/data',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {queryParam},
          pathParameters: const {},
          responses: const {},
        );

        const expectedMethod = '''
          Map<String, dynamic> _queryParameters({required List<List<Anonymous>> matrix}) {
            final result = <String, dynamic>{};
            final formEncoder = FormEncoder();
            result[r'matrix'] = formEncoder.encode(
              r'matrix',
              matrix.map((e) => e.map((e) => e.toJson()).toList()).toList(),
              explode: true,
              allowEmpty: false,
            );
            return result;
          }
        ''';

        final queryParameters =
            <({String normalizedName, QueryParameterObject parameter})>[
              (normalizedName: 'matrix', parameter: queryParam),
            ];

        final method = generator.generateQueryParametersMethod(
          operation,
          queryParameters,
        );

        expect(method, isA<Method>());
        expect(method.optionalParameters.first.named, isTrue);
        expect(method.optionalParameters.first.required, isTrue);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      });
    });

    group('path parameters', () {
      test('handles simple list of enums', () {
        final enumModel = EnumModel(
          context: context,
          values: const {'RED', 'GREEN', 'BLUE'},
          isNullable: false,
        );

        final listModel = ListModel(context: context, content: enumModel);

        final pathParam = PathParameterObject(
          name: 'colors',
          rawName: 'colors',
          description: 'List of colors',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: true,
          encoding: PathParameterEncoding.simple,
          model: listModel,
          context: context,
        );

        final operation = Operation(
          operationId: 'getByColors',
          context: context,
          summary: 'Get by colors',
          description: 'Gets data by colors',
          tags: const {},
          isDeprecated: false,
          path: '/data/{colors}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: {pathParam},
          responses: const {},
        );

        const expectedMethod = r'''
          String _path({required List<Anonymous> colors}) {
            final simpleEncoder = SimpleEncoder();
            return r'/data/'
              '${simpleEncoder.encode(colors.map((e) => e.toJson()).toList(), explode: true, allowEmpty: false)}';
          }
        ''';

        final pathParameters =
            <({String normalizedName, PathParameterObject parameter})>[
              (normalizedName: 'colors', parameter: pathParam),
            ];

        final method = generator.generatePathMethod(operation, pathParameters);

        expect(method, isA<Method>());
        expect(method.optionalParameters.first.named, isTrue);
        expect(method.optionalParameters.first.required, isTrue);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      });

      test('handles nested list of class models', () {
        final innerModel = ClassModel(context: context, properties: const {});
        final innerListModel = ListModel(context: context, content: innerModel);
        final outerListModel = ListModel(
          context: context,
          content: innerListModel,
        );

        final pathParam = PathParameterObject(
          name: 'matrix',
          rawName: 'matrix',
          description: 'Matrix of items',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: true,
          encoding: PathParameterEncoding.simple,
          model: outerListModel,
          context: context,
        );

        final operation = Operation(
          operationId: 'getMatrix',
          context: context,
          summary: 'Get matrix',
          description: 'Gets matrix data',
          tags: const {},
          isDeprecated: false,
          path: '/data/{matrix}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: {pathParam},
          responses: const {},
        );

        const expectedMethod = r'''
          String _path({required List<List<Anonymous>> matrix}) {
            final simpleEncoder = SimpleEncoder();
            return r'/data/'
              '${simpleEncoder.encode(matrix.map((e) => e.map((e) => e.toJson()).toList()).toList(), explode: true, allowEmpty: false)}';
          }
        ''';

        final pathParameters =
            <({String normalizedName, PathParameterObject parameter})>[
              (normalizedName: 'matrix', parameter: pathParam),
            ];

        final method = generator.generatePathMethod(operation, pathParameters);

        expect(method, isA<Method>());
        expect(method.optionalParameters.first.named, isTrue);
        expect(method.optionalParameters.first.required, isTrue);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      });
    });

    group('header parameters', () {
      test('handles simple list of enums', () {
        final enumModel = EnumModel(
          context: context,
          values: const {'RED', 'GREEN', 'BLUE'},
          isNullable: false,
        );

        final listModel = ListModel(context: context, content: enumModel);

        final headerParam = RequestHeaderObject(
          name: 'X-Colors',
          rawName: 'X-Colors',
          description: 'List of colors',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: true,
          model: listModel,
          encoding: HeaderParameterEncoding.simple,
          context: context,
        );

        final operation = Operation(
          operationId: 'getWithColors',
          context: context,
          summary: 'Get with colors',
          description: 'Gets data with colors',
          tags: const {},
          isDeprecated: false,
          path: '/data',
          method: HttpMethod.get,
          headers: {headerParam},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
        );

        const expectedMethod = '''
          Options _options({required List<Anonymous> xColors}) {
            final headers = <String, dynamic>{};
            const headerEncoder = SimpleEncoder();
            headers[r'X-Colors'] = headerEncoder.encode(
              xColors.map((e) => e.toJson()).toList(),
              explode: true,
              allowEmpty: false,
            );
            return Options(method: 'GET', headers: headers);
          }
        ''';

        final headers =
            <({String normalizedName, RequestHeaderObject parameter})>[
              (normalizedName: 'xColors', parameter: headerParam),
            ];

        final method = generator.generateOptionsMethod(operation, headers);

        expect(method, isA<Method>());
        expect(method.optionalParameters.first.named, isTrue);
        expect(method.optionalParameters.first.required, isTrue);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      });

      test('handles nested list of class models', () {
        final innerModel = ClassModel(context: context, properties: const {});
        final innerListModel = ListModel(context: context, content: innerModel);
        final outerListModel = ListModel(
          context: context,
          content: innerListModel,
        );

        final headerParam = RequestHeaderObject(
          name: 'X-Matrix',
          rawName: 'X-Matrix',
          description: 'Matrix of items',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: true,
          model: outerListModel,
          encoding: HeaderParameterEncoding.simple,
          context: context,
        );

        final operation = Operation(
          operationId: 'getWithMatrix',
          context: context,
          summary: 'Get with matrix',
          description: 'Gets data with matrix',
          tags: const {},
          isDeprecated: false,
          path: '/data',
          method: HttpMethod.get,
          headers: {headerParam},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
        );

        const expectedMethod = '''
          Options _options({required List<List<Anonymous>> xMatrix}) {
            final headers = <String, dynamic>{};
            const headerEncoder = SimpleEncoder();
            headers[r'X-Matrix'] = headerEncoder.encode(
              xMatrix.map((e) => e.map((e) => e.toJson()).toList()).toList(),
              explode: true,
              allowEmpty: false,
            );
            return Options(method: 'GET', headers: headers);
          }
        ''';

        final headers =
            <({String normalizedName, RequestHeaderObject parameter})>[
              (normalizedName: 'xMatrix', parameter: headerParam),
            ];

        final method = generator.generateOptionsMethod(operation, headers);

        expect(method, isA<Method>());
        expect(method.optionalParameters.first.named, isTrue);
        expect(method.optionalParameters.first.required, isTrue);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      });
    });
  });
}
