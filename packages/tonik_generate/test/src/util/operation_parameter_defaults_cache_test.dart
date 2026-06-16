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

  setUp(() {
    final previousRootLevel = Logger.root.level;
    Logger.root.level = Level.ALL;
    addTearDown(() => Logger.root.level = previousRootLevel);

    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
  });

  Operation makeOperation({required String id, required String path}) =>
      Operation(
        operationId: id,
        context: context,
        tags: const {},
        isDeprecated: false,
        path: path,
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

  QueryParameterObject queryString({
    required String name,
    Object? defaultValue,
  }) => QueryParameterObject(
    name: name,
    rawName: name,
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
    defaultValue: defaultValue,
  );

  QueryParameterObject queryDateTime({
    required String name,
    required String defaultValue,
  }) => QueryParameterObject(
    name: name,
    rawName: name,
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
    defaultValue: defaultValue,
  );

  NormalizedRequestParameters normalizeQuery(
    Set<QueryParameterObject> queryParameters,
  ) => normalizeRequestParameters(
    pathParameters: const {},
    queryParameters: queryParameters,
    headers: const {},
  );

  group('OperationDefaultsCache', () {
    test(
      'memoizes per operation — second forOperation(op) returns the same '
      'record instance the first call produced',
      () {
        final op = makeOperation(id: 'getRegion', path: '/region');
        final normalized = normalizeQuery({
          queryString(name: 'region', defaultValue: 'eu'),
        });

        final cache = OperationDefaultsCache(
          nameManager: nameManager,
          package: 'api',
        );

        final r1 = cache.forOperation(
          op,
          normalizedParams: normalized,
          operationClassName: 'Op',
          initialReservedNames: const {'_dio'},
        );
        final r2 = cache.forOperation(
          op,
          normalizedParams: normalized,
          operationClassName: 'Op',
          initialReservedNames: const {'_dio'},
        );

        expect(identical(r1.byName, r2.byName), isTrue);
        expect(identical(r1.fields, r2.fields), isTrue);
        expect(identical(r1.getters, r2.getters), isTrue);
        expect(r1.byName['region']?.memberName, 'regionDefault');
      },
    );

    test(
      'runtime-fallback routing log fires exactly once across two '
      'forOperation calls — pre-cache behaviour would have logged twice',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'OperationParameterDefaults',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final op = makeOperation(id: 'listSince', path: '/list');
        final normalized = normalizeQuery({
          queryDateTime(name: 'since', defaultValue: '2024-01-01T00:00:00Z'),
        });

        OperationDefaultsCache(nameManager: nameManager, package: 'api')
          ..forOperation(
            op,
            normalizedParams: normalized,
            operationClassName: 'Op',
            initialReservedNames: const {'_dio'},
          )
          ..forOperation(
            op,
            normalizedParams: normalized,
            operationClassName: 'Op',
            initialReservedNames: const {'_dio'},
          );

        final routingLogs = logs
            .where((r) => r.level == Level.FINE)
            .map((r) => r.message)
            .toList();
        expect(routingLogs, [
          'Routing default to runtime fallback for Op.since.',
        ]);
      },
    );

    test(
      'distinct Operation instances get independent results — '
      "one operation's defaults do not leak into the other's byName map",
      () {
        final opA = makeOperation(id: 'getA', path: '/a');
        final opB = makeOperation(id: 'getB', path: '/b');
        final normalizedA = normalizeQuery({
          queryString(name: 'alpha', defaultValue: 'a'),
        });
        final normalizedB = normalizeQuery({
          queryString(name: 'beta', defaultValue: 'b'),
        });

        final cache = OperationDefaultsCache(
          nameManager: nameManager,
          package: 'api',
        );

        final resultA = cache.forOperation(
          opA,
          normalizedParams: normalizedA,
          operationClassName: 'OpA',
          initialReservedNames: const {'_dio'},
        );
        final resultB = cache.forOperation(
          opB,
          normalizedParams: normalizedB,
          operationClassName: 'OpB',
          initialReservedNames: const {'_dio'},
        );

        expect(resultA.byName.keys, ['alpha']);
        expect(resultB.byName.keys, ['beta']);
        expect(identical(resultA.byName, resultB.byName), isFalse);
      },
    );
  });
}
