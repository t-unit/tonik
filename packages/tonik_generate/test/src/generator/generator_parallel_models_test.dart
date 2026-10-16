import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';
import 'package:tonik_generate/src/util/model_worker_pool.dart';

Map<String, String> _readModelTree(String root, String package) {
  final modelDir = Directory(path.join(root, package, 'lib', 'src', 'model'));
  if (!modelDir.existsSync()) return const {};
  final result = <String, String>{};
  final entries = modelDir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in entries) {
    result[path.basename(file.path)] = file.readAsStringSync();
  }
  return result;
}

Map<String, List<int>> _readGeneratedTree(String root) {
  final entries = Directory(root).listSync(recursive: true).whereType<File>();
  return {
    for (final file in entries)
      path.relative(file.path, from: root): file.readAsBytesSync(),
  };
}

ApiDocument _modelsDocument(int count, Context ctx) {
  final models = <Model>{};
  for (var i = 0; i < count; i++) {
    models.add(
      ClassModel(
        isDeprecated: false,
        name: 'Model$i',
        properties: const [],
        context: ctx,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      ),
    );
  }
  return ApiDocument(
    title: 'Test',
    version: '1.0.0',
    description: 'Test',
    models: models,
    responseHeaders: const {},
    requestHeaders: const {},
    servers: const {},
    operations: const {},
    responses: const <Response>{},
    queryParameters: const {},
    pathParameters: const {},
    cookieParameters: const {},
    requestBodies: const {},
    summary: null,
    contact: null,
    license: null,
    termsOfService: null,
    externalDocs: null,
  );
}

void main() {
  group('Generator parallel model path', () {
    late Directory tempDir;
    late Context ctx;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('gen_parallel_');
      ctx = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
      'dispatches via worker pool when threshold is met and workerCount > 1',
      () async {
        final apiDoc = _modelsDocument(Generator.parallelThreshold, ctx);

        var parallelPoolCount = 0;
        const parallelPackage = 'parallel_pkg';
        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: tempDir.path,
          package: parallelPackage,
          config: const TonikConfig(
            workerCount: 2,
            nameOverrides: NameOverridesConfig(
              schemas: {},
              properties: {},
              operations: {},
              parameters: {},
              enums: {},
              tags: {},
            ),
            contentTypes: {},
            contentMediaTypes: {},
            filter: FilterConfig(
              includeTags: [],
              excludeTags: [],
              excludeOperations: [],
              excludeSchemas: [],
            ),
            deprecated: DeprecatedConfig(
              operations: DeprecatedHandling.annotate,
              schemas: DeprecatedHandling.annotate,
              parameters: DeprecatedHandling.annotate,
              properties: DeprecatedHandling.annotate,
            ),
            enums: EnumConfig(
              generateUnknownCase: false,
              unknownCaseName: 'unknown',
            ),
            transport: TransportConfig(backend: TransportBackend.dio),
            useImmutableCollections: false,
          ),
          workerPoolFactory: () {
            parallelPoolCount++;
            return ModelWorkerPool();
          },
        );

        var serialPoolCount = 0;
        const serialPackage = 'serial_pkg';
        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: tempDir.path,
          package: serialPackage,
          config: const TonikConfig(
            workerCount: 1,
            nameOverrides: NameOverridesConfig(
              schemas: {},
              properties: {},
              operations: {},
              parameters: {},
              enums: {},
              tags: {},
            ),
            contentTypes: {},
            contentMediaTypes: {},
            filter: FilterConfig(
              includeTags: [],
              excludeTags: [],
              excludeOperations: [],
              excludeSchemas: [],
            ),
            deprecated: DeprecatedConfig(
              operations: DeprecatedHandling.annotate,
              schemas: DeprecatedHandling.annotate,
              parameters: DeprecatedHandling.annotate,
              properties: DeprecatedHandling.annotate,
            ),
            enums: EnumConfig(
              generateUnknownCase: false,
              unknownCaseName: 'unknown',
            ),
            transport: TransportConfig(backend: TransportBackend.dio),
            useImmutableCollections: false,
          ),
          workerPoolFactory: () {
            serialPoolCount++;
            return ModelWorkerPool();
          },
        );

        expect(
          parallelPoolCount,
          1,
          reason: 'parallel branch must instantiate the worker pool once',
        );
        expect(
          serialPoolCount,
          0,
          reason: 'serial branch must not instantiate the worker pool',
        );

        final parallelTree = _readModelTree(tempDir.path, parallelPackage);
        final serialTree = _readModelTree(tempDir.path, serialPackage);

        expect(parallelTree, isNotEmpty);
        expect(parallelTree.length, apiDoc.models.length);
        expect(parallelTree, serialTree);
      },
    );

    test(
      'colliding model names produce identical complete output across workers',
      () async {
        final barBaz = ClassModel(
          name: 'BarBaz',
          isDeprecated: false,
          properties: const [],
          context: ctx,
          examples: const [],
          nameOverride: null,
          description: null,
          additionalPropertiesPolicy: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );
        final baz = ClassModel(
          name: 'Baz',
          isDeprecated: false,
          properties: const [],
          context: ctx,
          examples: const [],
          nameOverride: null,
          description: null,
          additionalPropertiesPolicy: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );
        final foo = OneOfModel(
          name: 'Foo',
          models: [(model: barBaz, discriminatorValue: null)],
          context: ctx,
          isDeprecated: false,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );
        final fooBar = OneOfModel(
          name: 'FooBar',
          models: [(model: baz, discriminatorValue: null)],
          context: ctx,
          isDeprecated: false,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );
        final nullableChoice = OneOfModel(
          name: 'NullableChoice',
          isNullable: true,
          models: [(model: baz, discriminatorValue: null)],
          context: ctx,
          isDeprecated: false,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );
        final nullableObject = ClassModel(
          name: 'NullableChoiceBaz',
          isNullable: true,
          isDeprecated: false,
          properties: const [],
          context: ctx,
          examples: const [],
          nameOverride: null,
          description: null,
          additionalPropertiesPolicy: null,
          isReadOnly: false,
          isWriteOnly: false,
        );
        final nullableEnum = EnumModel<String>(
          name: 'NullableChoiceBazModel',
          values: {const EnumEntry(value: 'active', nameOverride: null)},
          isNullable: true,
          context: ctx,
          isDeprecated: false,
          examples: const [],
          nameOverride: null,
          description: null,
          defaultValue: null,
          fallbackValue: null,
          isReadOnly: false,
          isWriteOnly: false,
        );
        final resultResponse = ClassModel(
          name: 'ResultResponse',
          isDeprecated: false,
          properties: const [],
          context: ctx,
          examples: const [],
          nameOverride: null,
          description: null,
          additionalPropertiesPolicy: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );
        final get = OneOfModel(
          name: 'Get',
          models: [(model: resultResponse, discriminatorValue: null)],
          context: ctx,
          isDeprecated: false,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );
        final response = ResponseObject(
          name: null,
          context: ctx,
          headers: const {},
          description: 'OK',
          bodies: const {},
        );
        final operation = Operation(
          operationId: 'getResult',
          context: ctx,
          tags: const {},
          isDeprecated: false,
          path: '/result',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {const ExplicitResponseStatus(statusCode: 204): response},
          securitySchemes: const {},
          nameOverride: null,
          summary: null,
          description: null,
          requestBody: null,
        );
        final apiDoc = _modelsDocument(Generator.parallelThreshold, ctx);
        apiDoc.models = {
          foo,
          fooBar,
          nullableChoice,
          nullableObject,
          nullableEnum,
          get,
          resultResponse,
          barBaz,
          baz,
          ...apiDoc.models,
        };
        apiDoc
          ..operations = {operation}
          ..responses = {response};
        final parallelRoot = path.join(tempDir.path, 'parallel');
        final serialRoot = path.join(tempDir.path, 'serial');
        final pool = ModelWorkerPool();

        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: parallelRoot,
          package: 'collision_api',
          config: const TonikConfig(
            workerCount: 2,
            nameOverrides: NameOverridesConfig(
              schemas: {},
              properties: {},
              operations: {},
              parameters: {},
              enums: {},
              tags: {},
            ),
            contentTypes: {},
            contentMediaTypes: {},
            filter: FilterConfig(
              includeTags: [],
              excludeTags: [],
              excludeOperations: [],
              excludeSchemas: [],
            ),
            deprecated: DeprecatedConfig(
              operations: DeprecatedHandling.annotate,
              schemas: DeprecatedHandling.annotate,
              parameters: DeprecatedHandling.annotate,
              properties: DeprecatedHandling.annotate,
            ),
            enums: EnumConfig(
              generateUnknownCase: false,
              unknownCaseName: 'unknown',
            ),
            transport: TransportConfig(backend: TransportBackend.dio),
            useImmutableCollections: false,
          ),
          workerPoolFactory: () => pool,
        );
        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: serialRoot,
          package: 'collision_api',
          config: const TonikConfig(
            workerCount: 1,
            nameOverrides: NameOverridesConfig(
              schemas: {},
              properties: {},
              operations: {},
              parameters: {},
              enums: {},
              tags: {},
            ),
            contentTypes: {},
            contentMediaTypes: {},
            filter: FilterConfig(
              includeTags: [],
              excludeTags: [],
              excludeOperations: [],
              excludeSchemas: [],
            ),
            deprecated: DeprecatedConfig(
              operations: DeprecatedHandling.annotate,
              schemas: DeprecatedHandling.annotate,
              parameters: DeprecatedHandling.annotate,
              properties: DeprecatedHandling.annotate,
            ),
            enums: EnumConfig(
              generateUnknownCase: false,
              unknownCaseName: 'unknown',
            ),
            transport: TransportConfig(backend: TransportBackend.dio),
            useImmutableCollections: false,
          ),
        );

        expect(pool.spawnedWorkers, 2);
        expect(pool.exitedWorkers, 2);
        final parallelTree = _readGeneratedTree(parallelRoot);
        final serialTree = _readGeneratedTree(serialRoot);
        expect(parallelTree, isNotEmpty);
        expect(parallelTree, serialTree);
      },
    );

    test('runs serially when model count is below parallelThreshold', () async {
      final apiDoc = _modelsDocument(Generator.parallelThreshold - 1, ctx);

      var poolCount = 0;
      await const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'below_threshold_pkg',
        config: const TonikConfig(
          workerCount: 8,
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          filter: FilterConfig(
            includeTags: [],
            excludeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
        ),
        workerPoolFactory: () {
          poolCount++;
          return ModelWorkerPool();
        },
      );

      expect(
        poolCount,
        0,
        reason:
            'below-threshold path must skip the worker pool entirely '
            'regardless of how many workers the caller requested',
      );

      final tree = _readModelTree(tempDir.path, 'below_threshold_pkg');
      expect(tree, isNotEmpty);
      expect(tree.length, apiDoc.models.length);
    });
  });

  group('Generator.clampAutoWorkerCount', () {
    test('reserves one CPU for main and clamps to [1, 16]', () {
      expect(Generator.clampAutoWorkerCount(0), 1);
      expect(Generator.clampAutoWorkerCount(1), 1);
      expect(Generator.clampAutoWorkerCount(2), 1);
      expect(Generator.clampAutoWorkerCount(17), 16);
      expect(Generator.clampAutoWorkerCount(100), 16);
    });

    test('returns processorCount - 1 inside the clamp window', () {
      expect(Generator.clampAutoWorkerCount(3), 2);
      expect(Generator.clampAutoWorkerCount(8), 7);
      expect(Generator.clampAutoWorkerCount(16), 15);
    });
  });
}
