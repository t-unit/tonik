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
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
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
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
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
        expect(message, contains('value does not match the expected type'));
      },
    );

    test(
      'type mismatch on a boolean parameter emits a warning with the '
      'location, value, and reason',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
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
        expect(message, contains('value does not match the expected type'));
      },
    );

    test(
      'type mismatch on a string parameter (int value) emits a warning with '
      'the JSON-encoded numeric value',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
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
        expect(message, contains('value does not match the expected type'));
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
      'date-time target falls through to a runtime getter — no const field, '
      'isRuntime flag set, single routing warning emitted',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
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

        expect(result.fields, isEmpty);
        expect(result.getters, hasLength(1));
        expect(result.byName['since']?.memberName, 'sinceDefault');
        expect(result.byName['since']?.isRuntime, isTrue);
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        expect(
          warnings.single.message,
          contains('Routing default to runtime fallback for Op.since'),
        );
        expect(warnings.single.message, contains('non-const leaf'));
      },
    );

    test(
      'ClassModel target with default falls through to a runtime getter — '
      'no const field, isRuntime flag set, "object target" warning emitted',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
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

        expect(result.fields, isEmpty);
        expect(result.getters, hasLength(1));
        expect(result.byName['region']?.memberName, 'regionDefault');
        expect(result.byName['region']?.isRuntime, isTrue);
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        expect(warnings.single.message, contains('Op.region'));
        expect(warnings.single.message, contains('object target'));
      },
    );

    test(
      'header parameter with ClassModel default falls through to a runtime '
      'getter — no const field, no DefaultResolution drop callback fires',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final hPolicy = RequestHeaderObject(
          name: 'policy',
          rawName: 'X-Policy',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: ClassModel(
            isDeprecated: false,
            name: 'Policy',
            properties: const [],
            context: context,
            examples: const [],
          ),
          encoding: HeaderParameterEncoding.simple,
          context: context,
          examples: const [],
          defaultValue: const <String, Object?>{},
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: const {},
          headers: {hPolicy},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.fields, isEmpty);
        expect(result.getters, hasLength(1));
        expect(result.byName['policy']?.memberName, 'policyDefault');
        expect(result.byName['policy']?.isRuntime, isTrue);
        final warnings = logs
            .where(
              (r) =>
                  r.level == Level.WARNING &&
                  r.loggerName == 'OperationParameterDefaults',
            )
            .toList();
        expect(warnings, hasLength(1));
        expect(
          warnings.single.message,
          contains('Routing default to runtime fallback for Op.X-Policy'),
        );
        expect(warnings.single.message, contains('(header,'));
        expect(warnings.single.message, contains('object target'));
        expect(
          logs.where(
            (r) =>
                r.level == Level.WARNING &&
                r.loggerName == 'DefaultResolution',
          ),
          isEmpty,
        );
      },
    );

    test(
      'AllOf composite target with default falls through to a runtime getter '
      'without emitting a const field, "composite target" warning emitted',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
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
          model: AllOfModel(
            isDeprecated: false,
            name: 'Region',
            models: const {},
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

        expect(result.fields, isEmpty);
        expect(result.getters, hasLength(1));
        expect(result.byName['region']?.memberName, 'regionDefault');
        expect(result.byName['region']?.isRuntime, isTrue);
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        expect(warnings.single.message, contains('Op.region'));
        expect(warnings.single.message, contains('composite target'));
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
      'enum parameter with a valid defaulted variant emits a static const '
      'field referencing the matching enum variant',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
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

        expect(result.byName.keys, ['order']);
        expect(result.fields, hasLength(1));
        final field = result.fields.single;
        expect(field.name, 'orderDefault');
        expect(field.type?.symbol, 'Order');
        expect(renderAssignment(field.assignment), 'Order.desc');
        expect(logs.where((r) => r.level == Level.WARNING), isEmpty);
      },
    );

    test(
      'header enum parameter with a valid defaulted variant emits a static '
      'const field referencing the matching enum variant',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final mode = RequestHeaderObject(
          name: 'mode',
          rawName: 'X-Mode',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: EnumModel<String>(
            name: 'Mode',
            values: {
              const EnumEntry(value: 'fast'),
              const EnumEntry(value: 'slow'),
            },
            isNullable: false,
            isDeprecated: false,
            context: context,
            examples: const [],
          ),
          encoding: HeaderParameterEncoding.simple,
          context: context,
          examples: const [],
          defaultValue: 'slow',
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: const {},
          headers: {mode},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName.keys, ['mode']);
        expect(result.fields, hasLength(1));
        final field = result.fields.single;
        expect(field.name, 'modeDefault');
        expect(field.static, isTrue);
        expect(field.modifier, FieldModifier.constant);
        expect(field.type?.symbol, 'Mode');
        expect(renderAssignment(field.assignment), 'Mode.slow');
        expect(logs.where((r) => r.level == Level.WARNING), isEmpty);
      },
    );

    test(
      'path enum parameter with a valid defaulted variant emits a static '
      'const field referencing the matching enum variant',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final kind = PathParameterObject(
          name: 'kind',
          rawName: 'kind',
          description: null,
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: EnumModel<String>(
            name: 'Kind',
            values: {
              const EnumEntry(value: 'big'),
              const EnumEntry(value: 'small'),
            },
            isNullable: false,
            isDeprecated: false,
            context: context,
            examples: const [],
          ),
          encoding: PathParameterEncoding.simple,
          context: context,
          examples: const [],
          defaultValue: 'big',
        );

        final normalized = normalizeRequestParameters(
          pathParameters: {kind},
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

        expect(result.byName.keys, ['kind']);
        expect(result.fields, hasLength(1));
        final field = result.fields.single;
        expect(field.name, 'kindDefault');
        expect(field.static, isTrue);
        expect(field.modifier, FieldModifier.constant);
        expect(field.type?.symbol, 'Kind');
        expect(renderAssignment(field.assignment), 'Kind.big');
        expect(logs.where((r) => r.level == Level.WARNING), isEmpty);
      },
    );

    test(
      'cookie enum parameter with a valid defaulted variant emits a static '
      'const field referencing the matching enum variant',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final flavor = CookieParameterObject(
          name: 'flavor',
          rawName: 'flavor',
          description: null,
          isRequired: false,
          isDeprecated: false,
          explode: false,
          model: EnumModel<String>(
            name: 'Flavor',
            values: {
              const EnumEntry(value: 'sweet'),
              const EnumEntry(value: 'salty'),
            },
            isNullable: false,
            isDeprecated: false,
            context: context,
            examples: const [],
          ),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: 'salty',
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: const {},
          headers: const {},
          cookieParameters: {flavor},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName.keys, ['flavor']);
        expect(result.fields, hasLength(1));
        final field = result.fields.single;
        expect(field.name, 'flavorDefault');
        expect(field.static, isTrue);
        expect(field.modifier, FieldModifier.constant);
        expect(field.type?.symbol, 'Flavor');
        expect(renderAssignment(field.assignment), 'Flavor.salty');
        expect(logs.where((r) => r.level == Level.WARNING), isEmpty);
      },
    );

    test(
      'int-valued enum query parameter materialises a static const field '
      'referencing the matching enum variant',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final priority = QueryParameterObject(
          name: 'priority',
          rawName: 'priority',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: EnumModel<int>(
            name: 'Tier',
            values: {
              const EnumEntry(value: 1),
              const EnumEntry(value: 2),
              const EnumEntry(value: 3),
            },
            isNullable: false,
            isDeprecated: false,
            context: context,
            examples: const [],
          ),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: 2,
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {priority},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName.keys, ['priority']);
        expect(result.fields, hasLength(1));
        final field = result.fields.single;
        expect(field.name, 'priorityDefault');
        expect(field.static, isTrue);
        expect(field.modifier, FieldModifier.constant);
        expect(field.type?.symbol, 'Tier');
        expect(renderAssignment(field.assignment), 'Tier.two');
        expect(logs.where((r) => r.level == Level.WARNING), isEmpty);
      },
    );

    test(
      'enum query parameter with default value outside the enum values is '
      'dropped with a query-location warning',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
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
          defaultValue: 'archived',
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

        expect(result.byName.containsKey('order'), isFalse);
        expect(result.fields, isEmpty);
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        final message = warnings.single.message;
        expect(message, contains('Op.order'));
        expect(message, contains('(query,'));
        expect(message, contains('"archived"'));
        expect(message, contains('value is not one of the enum values'));
      },
    );

    test(
      'alias-wrapped enum default surfaces via effectiveDefaultValue and '
      'materialises the matching variant const',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final status = QueryParameterObject(
          name: 'status',
          rawName: 'status',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: AliasModel(
            name: 'StatusAlias',
            model: EnumModel<String>(
              name: 'Status',
              values: {
                const EnumEntry(value: 'active'),
                const EnumEntry(value: 'inactive'),
              },
              isNullable: false,
              isDeprecated: false,
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
            defaultValue: 'active',
          ),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final normalized = normalizeRequestParameters(
          pathParameters: const {},
          queryParameters: {status},
          headers: const {},
        );

        final result = resolveOperationParameterDefaults(
          normalizedParams: normalized,
          operationClassName: 'Op',
          nameManager: nameManager,
          package: 'api',
          initialReservedNames: const {'_dio'},
        );

        expect(result.byName['status']?.memberName, 'statusDefault');
        expect(result.fields, hasLength(1));
        final field = result.fields.single;
        expect(field.name, 'statusDefault');
        expect(field.static, isTrue);
        expect(field.modifier, FieldModifier.constant);
        expect(field.type?.symbol, 'StatusAlias');
        expect(renderAssignment(field.assignment), 'Status.active');
        expect(logs.where((r) => r.level == Level.WARNING), isEmpty);
      },
    );

    test(
      'warning formatter falls back to toString when the type-mismatched raw '
      'default is not JSON-encodable (e.g. a YAML-parsed DateTime)',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final yamlDateTime = DateTime.utc(2024, 6, 15);
        final bad = QueryParameterObject(
          name: 'count',
          rawName: 'count',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: IntegerModel(context: context),
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
        final suppressedSub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(suppressedLogs.add);
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
        final emittedSub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(emittedLogs.add);
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
      );

      expect(
        names,
        containsAll(<String>[
          'call',
          'body',
          'cancelToken',
          'region',
        ]),
      );
    });

    test('omits body when no request body is present', () {
      const normalized = NormalizedRequestParameters(
        pathParameters: [],
        queryParameters: [],
        headers: [],
        cookieParameters: [],
      );

      final names = initialOperationDefaultReservedNames(
        normalizedParams: normalized,
        hasRequestBody: false,
      );

      expect(names.contains('body'), isFalse);
      expect(names, containsAll(<String>['cancelToken', 'call']));
    });
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

    test(
      'preserves isRuntime: true when qualifying a runtime local default '
      'and keeps the defaultToCode shape pointing at the static getter',
      () {
        const local = OperationParameterDefault.local(
          memberName: 'sinceDefault',
          isRuntime: true,
        );

        final qualified = local.withOwner(
          className: 'ListThings',
          url: 'package:api/src/operation/list_things.dart',
        );

        expect(qualified.isRuntime, isTrue);
        expect(qualified.memberName, 'sinceDefault');
        expect(
          qualified.defaultToCode().accept(emitter).toString(),
          'ListThings.sinceDefault',
        );
      },
    );
  });
}
