import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/operation/options_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

void main() {
  late OptionsGenerator generator;
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
    generator = OptionsGenerator(
      nameManager: nameManager,
      package: 'package:api/api.dart',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('generateOptionsMethod', () {
    test('returns Options with GET method for GET operation', () {
      final operation = Operation(
        operationId: 'getUsers',
        context: context,
        summary: 'Get users',
        description: 'Gets a list of users',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
          Options _options() {
            return Options(method: 'GET');
          }
        ''';

      final method = generator.generateOptionsMethod(operation, []);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), contains('Options'));
      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('returns Options with POST method for POST operation', () {
      final operation = Operation(
        operationId: 'createUser',
        context: context,
        summary: 'Create user',
        description: 'Creates a new user',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.post,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
          Options _options() {
            return Options(method: 'POST');
          }
        ''';

      final method = generator.generateOptionsMethod(operation, []);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), contains('Options'));
      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('returns Options with PUT method for PUT operation', () {
      final operation = Operation(
        operationId: 'createUser',
        context: context,
        summary: 'Create user',
        description: 'Creates a new user',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.put,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
          Options _options() {
            return Options(method: 'PUT');
          }
        ''';

      final method = generator.generateOptionsMethod(operation, []);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), contains('Options'));
      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('returns Options with DELETE method for DELETE operation', () {
      final operation = Operation(
        operationId: 'createUser',
        context: context,
        summary: 'Create user',
        description: 'Creates a new user',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.delete,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
          Options _options() {
            return Options(method: 'DELETE');
          }
        ''';

      final method = generator.generateOptionsMethod(operation, []);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), contains('Options'));
      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('includes headers when operation has headers', () {
      final requestHeader = RequestHeaderObject(
        name: 'X-My-Header',
        rawName: 'X-My-Header',
        description: 'A custom header',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'operationWithHeader',
        context: context,
        summary: 'Operation with header',
        description: 'An operation that requires a header',
        tags: const {},
        isDeprecated: false,
        path: '/with-header',
        method: HttpMethod.get,
        headers: {requestHeader},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
          Options _options({required String xMyHeader}) {
            final headers = <String, dynamic>{};
            const headerEncoder = SimpleEncoder();
            headers[r'X-My-Header'] = headerEncoder.encode(
              xMyHeader,
              explode: false,
              allowEmpty: false,
            );
            return Options(method: 'GET', headers: headers);
          }
        ''';

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (normalizedName: 'xMyHeader', parameter: requestHeader),
          ];
      final method = generator.generateOptionsMethod(operation, headers);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), 'Options');

      expect(method.optionalParameters, hasLength(1));
      expect(method.optionalParameters.first.name, 'xMyHeader');

      expect(method.optionalParameters.first.type?.symbol, 'String');
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isTrue);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('handles headers with different types and requirements', () {
      // Required string header that doesn't allow empty values
      final requiredStringHeader = RequestHeaderObject(
        name: 'X-Required-String',
        rawName: 'X-Required-String',
        description: 'A required string header',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      // Required date header that allows empty values
      final requiredDateHeader = RequestHeaderObject(
        name: 'X-Required-Date',
        rawName: 'X-Required-Date',
        description: 'A required date header that allows empty values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        model: DateTimeModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      // Optional boolean header
      final optionalBoolHeader = RequestHeaderObject(
        name: 'X-Optional-Bool',
        rawName: 'X-Optional-Bool',
        description: 'An optional boolean header',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: BooleanModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      // Optional list header
      final optionalListHeader = RequestHeaderObject(
        name: 'X-Optional-List',
        rawName: 'X-Optional-List',
        description: 'An optional list of strings header',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: true,
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'operationWithComplexHeaders',
        context: context,
        summary: 'Operation with complex headers',
        description:
            'An operation that has headers of different '
            'types and requirements',
        tags: const {},
        isDeprecated: false,
        path: '/with-complex-headers',
        method: HttpMethod.get,
        headers: {
          requiredStringHeader,
          requiredDateHeader,
          optionalBoolHeader,
          optionalListHeader,
        },
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (
              normalizedName: 'xRequiredString',
              parameter: requiredStringHeader,
            ),
            (normalizedName: 'xRequiredDate', parameter: requiredDateHeader),
            (normalizedName: 'xOptionalBool', parameter: optionalBoolHeader),
            (normalizedName: 'xOptionalList', parameter: optionalListHeader),
          ];

      const expectedMethod = '''
          Options _options({
            required String xRequiredString,
            required DateTime xRequiredDate,
            bool? xOptionalBool,
            List<String>? xOptionalList,
          }) {
            final headers = <String, dynamic>{};
            const headerEncoder = SimpleEncoder();
            headers[r'X-Required-String'] = headerEncoder.encode(
              xRequiredString,
              explode: false,
              allowEmpty: false,
            );
            headers[r'X-Required-Date'] = headerEncoder.encode(
              xRequiredDate.toIso8601String(),
              explode: false,
              allowEmpty: true,
            );
            if (xOptionalBool != null) {
              headers[r'X-Optional-Bool'] = headerEncoder.encode(
                xOptionalBool,
                explode: false,
                allowEmpty: false,
              );
            }
            if (xOptionalList != null) {
              headers[r'X-Optional-List'] = headerEncoder.encode(
                xOptionalList,
                explode: true,
                allowEmpty: false,
              );
            }
            return Options(method: 'GET', headers: headers);
          }
        ''';

      final method = generator.generateOptionsMethod(operation, headers);

      expect(method, isA<Method>());
      expect(method.optionalParameters, hasLength(4));

      final paramNames = method.optionalParameters.map((p) => p.name).toList();
      expect(paramNames.contains('xRequiredString'), isTrue);
      expect(paramNames.contains('xRequiredDate'), isTrue);
      expect(paramNames.contains('xOptionalBool'), isTrue);
      expect(paramNames.contains('xOptionalList'), isTrue);

      final methodString = format(method.accept(emitter).toString());

      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('encodes headers with allowEmpty and explode flags', () {
      final requestHeader = RequestHeaderObject(
        name: 'X-My-Header',
        rawName: 'X-My-Header',
        description: 'A custom header',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: true,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'operationWithHeader',
        context: context,
        summary: 'Operation with header',
        description: 'An operation that requires a header',
        tags: const {},
        isDeprecated: false,
        path: '/with-header',
        method: HttpMethod.get,
        headers: {requestHeader},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Options _options({required String xMyHeader}) {
          final headers = <String, dynamic>{};
          const headerEncoder = SimpleEncoder();
          headers[r'X-My-Header'] = headerEncoder.encode(
            xMyHeader,
            explode: true,
            allowEmpty: true,
          );
          return Options(method: 'GET', headers: headers);
        }
      ''';

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (normalizedName: 'xMyHeader', parameter: requestHeader),
          ];
      final method = generator.generateOptionsMethod(operation, headers);

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

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
}
