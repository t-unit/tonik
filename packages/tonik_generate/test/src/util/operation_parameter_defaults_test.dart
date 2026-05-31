import 'package:code_builder/code_builder.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';

void main() {
  late NameManager nameManager;
  late Context context;
  late DartEmitter emitter;

  setUp(() {
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  String renderAssignment(Code? assignment) =>
      assignment == null ? '' : assignment.accept(emitter).toString();

  group('resolveOperationParameterDefaults', () {
    test(
      'returns empty result when no parameter carries a default',
      () {
        final normalized = normalizeRequestParameters(
          pathParameters: {
            PathParameterObject(
              name: 'id',
              rawName: 'id',
              description: null,
              isRequired: true,
              isDeprecated: false,
              allowEmptyValue: false,
              explode: false,
              model: StringModel(context: context),
              encoding: PathParameterEncoding.simple,
              context: context,
              examples: const [],
              defaultValue: null,
            ),
          },
          queryParameters: const {},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName, isEmpty);
        expect(result.fields, isEmpty);
      },
    );

    test('materialises primitive defaults across all four locations '
        'in path → query → header → cookie field order', () {
      final pathId = PathParameterObject(
        name: 'id',
        rawName: 'id',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
        examples: const [],
        defaultValue: 'x',
      );
      final qRegion = QueryParameterObject(
        name: 'region',
        rawName: 'region',
        description: null,
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: StringModel(context: context),
        encoding: QueryParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: 'us',
      );
      final hRetries = RequestHeaderObject(
        name: 'retries',
        rawName: 'X-Retries',
        description: null,
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: IntegerModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
        examples: const [],
        defaultValue: 5,
      );
      final cTracking = CookieParameterObject(
        name: 'tracking',
        rawName: 'tracking',
        description: null,
        isRequired: false,
        isDeprecated: false,
        explode: false,
        model: BooleanModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: false,
      );

      final normalized = normalizeRequestParameters(
        pathParameters: {pathId},
        queryParameters: {qRegion},
        headers: {hRetries},
        cookieParameters: {cTracking},
      );

      final result = resolveOperationParameterDefaults(
        normalizedParams: normalized,
        operationClassName: 'ListThings',
        nameManager: nameManager,
        package: 'api',
        initialReservedNames: const {'_dio'},
      );

      expect(
        result.byName.keys.toList(),
        ['id', 'region', 'retries', 'tracking'],
      );
      expect(
        result.fields.map((f) => f.name).toList(),
        ['idDefault', 'regionDefault', 'retriesDefault', 'trackingDefault'],
      );

      expect(result.fields[0].type?.symbol, 'String');
      expect(result.fields[0].static, isTrue);
      expect(result.fields[0].modifier, FieldModifier.constant);
      expect(renderAssignment(result.fields[0].assignment), "r'x'");

      expect(result.fields[1].type?.symbol, 'String');
      expect(renderAssignment(result.fields[1].assignment), "r'us'");

      expect(result.fields[2].type?.symbol, 'int');
      expect(renderAssignment(result.fields[2].assignment), '5');

      expect(result.fields[3].type?.symbol, 'bool');
      expect(renderAssignment(result.fields[3].assignment), 'false');
    });

    test(
      'drops type-mismatched default with a single warning, no field, '
      'no map entry',
      () {
        final logs = <LogRecord>[];
        final sub = Logger('OperationParameterDefaults')
            .onRecord
            .listen(logs.add);
        addTearDown(sub.cancel);

        final bad = QueryParameterObject(
          name: 'page',
          rawName: 'page',
          description: null,
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: IntegerModel(context: context),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: 'not-a-number',
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {bad},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'BadOp',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName, isEmpty);
        expect(result.fields, isEmpty);
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        expect(warnings.single.message, contains('BadOp.page'));
      },
    );

    test(
      'alias-carried default surfaces via effectiveDefaultValue',
      () {
        final region = QueryParameterObject(
          name: 'region',
          rawName: 'region',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: AliasModel(
            name: 'Region',
            model: StringModel(context: context),
            context: context,
            examples: const [],
            defaultValue: 'us',
          ),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {region},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName['region']?.memberName, 'regionDefault');
        expect(result.fields, hasLength(1));
        expect(renderAssignment(result.fields.single.assignment), "r'us'");
      },
    );

    test(
      'parameter-local default takes precedence over alias default',
      () {
        final region = QueryParameterObject(
          name: 'region',
          rawName: 'region',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: AliasModel(
            name: 'Region',
            model: StringModel(context: context),
            context: context,
            examples: const [],
            defaultValue: 'us',
          ),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: 'eu',
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {region},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(renderAssignment(result.fields.single.assignment), "r'eu'");
      },
    );

    test(
      'collision: parameter normalized name matches the candidate default '
      'name — suffix is appended',
      () {
        final region = QueryParameterObject(
          name: 'region',
          rawName: 'region',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: StringModel(context: context),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: 'us',
        );
        final preExisting = QueryParameterObject(
          name: 'regionDefault',
          rawName: 'regionDefault',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: StringModel(context: context),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {region, preExisting},
          headers: const {},
        );

        final reserved = <String>{
          '_dio',
          for (final p in normalized.queryParameters) p.normalizedName,
        };

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: reserved,
        );

        expect(result.byName['region']?.memberName, 'regionDefault2');
      },
    );

    test(
      'date-time target with a valid date-time literal emits no field '
      'and no warning',
      () {
        final logs = <LogRecord>[];
        final sub = Logger('OperationParameterDefaults')
            .onRecord
            .listen(logs.add);
        addTearDown(sub.cancel);

        final since = QueryParameterObject(
          name: 'since',
          rawName: 'since',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: DateTimeModel(context: context),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: '2024-01-01T00:00:00Z',
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {since},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName.containsKey('since'), isFalse);
        expect(result.fields, isEmpty);
        expect(logs.where((r) => r.level == Level.WARNING), isEmpty);
      },
    );

    test(
      'composite target with default emits no field and no warning',
      () {
        final logs = <LogRecord>[];
        final sub = Logger('OperationParameterDefaults')
            .onRecord
            .listen(logs.add);
        addTearDown(sub.cancel);

        final region = QueryParameterObject(
          name: 'region',
          rawName: 'region',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: ClassModel(
            isDeprecated: false,
            name: 'Region',
            properties: const [],
            context: context,
            examples: const [],
          ),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: const <String, Object?>{},
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {region},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName, isEmpty);
        expect(result.fields, isEmpty);
        expect(logs.where((r) => r.level == Level.WARNING), isEmpty);
      },
    );
  });

  group('initialOperationDefaultReservedNames', () {
    test('reserves the standard operation class member names', () {
      final region = QueryParameterObject(
        name: 'region',
        rawName: 'region',
        description: null,
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: StringModel(context: context),
        encoding: QueryParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final normalized = normalizeRequestParameters(
        pathParameters: const {},
        queryParameters: {region},
        headers: const {},
      );

      final names = initialOperationDefaultReservedNames(
        normalizedParams: normalized,
        hasRequestBody: true,
        hasResponses: true,
        hasQueryParameters: true,
      );

      expect(names, containsAll(<String>[
        '_dio',
        'call',
        '_path',
        '_data',
        '_options',
        '_queryParameters',
        '_parseResponse',
        'body',
        'cancelToken',
        'region',
      ]));
    });

    test(
      'omits body, query, response method names when not applicable',
      () {
        const normalized = NormalizedRequestParameters(
          pathParameters: [],
          queryParameters: [],
          headers: [],
          cookieParameters: [],
        );

        final names = initialOperationDefaultReservedNames(
          normalizedParams: normalized,
          hasRequestBody: false,
          hasResponses: false,
          hasQueryParameters: false,
        );

        expect(names.contains('body'), isFalse);
        expect(names.contains('_queryParameters'), isFalse);
        expect(names.contains('_parseResponse'), isFalse);
        expect(names, containsAll(<String>['_dio', 'cancelToken', 'call']));
      },
    );
  });
}
