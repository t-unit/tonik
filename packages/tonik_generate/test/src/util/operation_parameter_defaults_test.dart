import 'dart:async';

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

    test(
      'explicit defaultValue: null is treated as no default — no field, '
      'no warning, no byName entry',
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
        final message = warnings.single.message;
        expect(message, contains('BadOp.page'));
        expect(message, contains('(query,'));
        expect(message, contains('expected IntegerModel'));
        expect(message, contains('"not-a-number"'));
        expect(message, contains('value does not match the parameter type'));
      },
    );

    test(
      'type mismatch on a boolean parameter emits a warning with the '
      'location, value, and reason',
      () {
        final logs = <LogRecord>[];
        final sub = Logger('OperationParameterDefaults')
            .onRecord
            .listen(logs.add);
        addTearDown(sub.cancel);

        final bad = QueryParameterObject(
          name: 'enabled',
          rawName: 'enabled',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: BooleanModel(context: context),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: 'true',
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {bad},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'BoolOp',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName, isEmpty);
        expect(result.fields, isEmpty);
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        final message = warnings.single.message;
        expect(message, contains('BoolOp.enabled'));
        expect(message, contains('(query,'));
        expect(message, contains('expected BooleanModel'));
        expect(message, contains('"true"'));
        expect(message, contains('value does not match the parameter type'));
      },
    );

    test(
      'type mismatch on a string parameter (int value) emits a warning with '
      'the JSON-encoded numeric value',
      () {
        final logs = <LogRecord>[];
        final sub = Logger('OperationParameterDefaults')
            .onRecord
            .listen(logs.add);
        addTearDown(sub.cancel);

        final bad = QueryParameterObject(
          name: 'name',
          rawName: 'name',
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
          defaultValue: 42,
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {bad},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'StrOp',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName, isEmpty);
        expect(result.fields, isEmpty);
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        final message = warnings.single.message;
        expect(message, contains('StrOp.name'));
        expect(message, contains('(query,'));
        expect(message, contains('expected StringModel'));
        expect(message, contains('value: 42'));
        expect(message, contains('value does not match the parameter type'));
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
      'date-time target emits no field but warns that the value is not '
      'const-materialisable',
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
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        final message = warnings.single.message;
        expect(message, contains('Op.since'));
        expect(message, contains('(query,'));
        expect(message, contains('expected DateTimeModel'));
        expect(message, contains('"2024-01-01T00:00:00Z"'));
        expect(
          message,
          contains('cannot be expressed as a const Dart expression'),
        );
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

    test(
      'double parameter with numeric default materialises a double-typed '
      'const field',
      () {
        final ratio = QueryParameterObject(
          name: 'ratio',
          rawName: 'ratio',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: DoubleModel(context: context),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: 1.5,
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {ratio},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName['ratio']?.memberName, 'ratioDefault');
        expect(result.fields, hasLength(1));
        expect(result.fields.single.type?.symbol, 'double');
        expect(renderAssignment(result.fields.single.assignment), '1.5');
      },
    );

    test(
      'number parameter with int default materialises a num-typed '
      'const field',
      () {
        final ratio = QueryParameterObject(
          name: 'ratio',
          rawName: 'ratio',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: NumberModel(context: context),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: 2,
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {ratio},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName['ratio']?.memberName, 'ratioDefault');
        expect(result.fields, hasLength(1));
        expect(result.fields.single.type?.symbol, 'num');
        expect(renderAssignment(result.fields.single.assignment), '2');
      },
    );

    test(
      'enum parameter with a defaulted variant emits no field and no '
      'warning (composite/non-PrimitiveModel — silent by design)',
      () {
        final logs = <LogRecord>[];
        final sub = Logger('OperationParameterDefaults')
            .onRecord
            .listen(logs.add);
        addTearDown(sub.cancel);

        final order = QueryParameterObject(
          name: 'order',
          rawName: 'order',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: EnumModel<String>(
            name: 'Order',
            values: {
              const EnumEntry(value: 'asc'),
              const EnumEntry(value: 'desc'),
            },
            isNullable: false,
            isDeprecated: false,
            context: context,
            examples: const [],
          ),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: 'desc',
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {order},
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

    test(
      'warning formatter falls back to toString when the raw default is '
      'not JSON-encodable (e.g. a YAML-parsed DateTime)',
      () {
        final logs = <LogRecord>[];
        final sub = Logger('OperationParameterDefaults')
            .onRecord
            .listen(logs.add);
        addTearDown(sub.cancel);

        final yamlDateTime = DateTime.utc(2024, 6, 15);
        final bad = QueryParameterObject(
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
          defaultValue: yamlDateTime,
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {bad},
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
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        expect(warnings.single.message, contains(yamlDateTime.toString()));
      },
    );

    test(
      'emitWarnings: false suppresses the dropped-default warning while '
      'the default emitWarnings: true logs exactly once',
      () {
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

        final suppressedLogs = <LogRecord>[];
        final suppressedSub = Logger('OperationParameterDefaults')
            .onRecord
            .listen(suppressedLogs.add);
        resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'BadOp',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
          emitWarnings: false,
        );
        unawaited(suppressedSub.cancel());
        expect(
          suppressedLogs.where((r) => r.level == Level.WARNING),
          isEmpty,
        );

        final emittedLogs = <LogRecord>[];
        final emittedSub = Logger('OperationParameterDefaults')
            .onRecord
            .listen(emittedLogs.add);
        addTearDown(emittedSub.cancel);
        resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'BadOp',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );
        expect(
          emittedLogs.where((r) => r.level == Level.WARNING),
          hasLength(1),
        );
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

  group('OperationParameterDefault.withOwner', () {
    test('qualifies a local default with the supplied owner', () {
      const local = OperationParameterDefault.local(
        memberName: 'regionDefault',
      );

      final qualified = local.withOwner(
        className: 'ListThings',
        url: 'package:api/src/operation/list_things.dart',
      );

      expect(
        qualified.defaultToCode().accept(emitter).toString(),
        'ListThings.regionDefault',
      );
    });

    test('asserts when called on an already-qualified default', () {
      const qualified = OperationParameterDefault.qualified(
        memberName: 'regionDefault',
        className: 'ListThings',
        url: 'package:api/src/operation/list_things.dart',
      );

      expect(
        () => qualified.withOwner(
          className: 'OtherClass',
          url: 'package:api/src/operation/other_class.dart',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
