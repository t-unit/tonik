import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

import 'operation_execution_test_support.dart';

void main() {
  late Directory output;

  setUp(() => output = Directory.systemTemp.createTempSync('tonik_shape_'));
  tearDown(() => output.deleteSync(recursive: true));

  test('base facility is selected and emitted', () async {
    await generateExecutionPackage(
      output,
      package: dioRuntimePackage,
      backend: TransportBackend.dio,
    );
    final generatorRoot = path.join(
      repositoryRoot,
      'packages',
      'tonik_generate',
    );
    expect(
      File(
        path.join(
          generatorRoot,
          'lib/src/operation/operation_base_generator.dart',
        ),
      ),
      exists,
    );
    expect(
      File(
        path.join(
          generatorRoot,
          'lib/src/operation/operation_base_file_generator.dart',
        ),
      ),
      exists,
    );
    expect(
      File(
        path.join(
          generatorRoot,
          'lib/src/transport/transport_backend_generator.dart',
        ),
      ).readAsStringSync(),
      contains('OperationBaseGenerator get operationBaseGenerator'),
    );
    expect(
      operationSource(output, dioRuntimePackage, 'dio_operation.dart'),
      contains('abstract base class DioOperation<T>'),
    );
  });

  for (final backendCase in const [
    (TransportBackend.dio, dioRuntimePackage, 'DioOperation', 'HttpOperation'),
    (
      TransportBackend.http,
      httpRuntimePackage,
      'HttpOperation',
      'DioOperation',
    ),
  ]) {
    test('${backendCase.$3} package contains only its hidden base', () async {
      await generateExecutionPackage(
        output,
        package: backendCase.$2,
        backend: backendCase.$1,
      );
      final operationDir = Directory(
        path.join(output.path, backendCase.$2, 'lib/src/operation'),
      );
      final sources = operationDir
          .listSync()
          .whereType<File>()
          .map((file) => file.readAsStringSync())
          .toList();
      expect(
        sources.where(
          (source) => source.contains('abstract base class ${backendCase.$3}<'),
        ),
        hasLength(1),
      );
      expect(
        sources.any((source) => source.contains('class ${backendCase.$4}<')),
        isFalse,
      );
      final library = File(
        path.join(output.path, backendCase.$2, 'lib', '${backendCase.$2}.dart'),
      ).readAsStringSync();
      expect(library, isNot(contains('${backendCase.$3.toLowerCase()}.dart')));
      expect(library, isNot(contains('operation/dio_operation.dart')));
      expect(library, isNot(contains('operation/http_operation.dart')));
    });
  }

  for (final backendCase in const [
    (TransportBackend.dio, dioRuntimePackage, 'DioOperation<String>'),
    (TransportBackend.http, httpRuntimePackage, 'HttpOperation<String>'),
  ]) {
    test('${backendCase.$2} operations inherit state through super', () async {
      await generateExecutionPackage(
        output,
        package: backendCase.$2,
        backend: backendCase.$1,
      );
      final source = normalizeGeneratedSource(
        operationSource(output, backendCase.$2, 'value_response.dart'),
      );
      expect(source, contains('extends ${backendCase.$3}'));
      expect(source, contains('final class ValueResponse'));
      expect(
        source,
        contains('ValueResponse(super.baseUrl, super.clientAccessor)'),
      );
      expect(source, isNot(contains('final String _baseUrl')));
      expect(source, isNot(matches(RegExp(r'final\s+\S+ Function\(\) _'))));
      for (final helper in [
        '_path(',
        '_data(',
        '_options(',
        '_parseResponse(',
      ]) {
        expect(source, contains(helper));
      }
    });
  }

  test('public call and API-client initialization stay compatible', () async {
    await generateExecutionPackage(
      output,
      package: dioRuntimePackage,
      backend: TransportBackend.dio,
    );
    final operation = normalizeGeneratedSource(
      operationSource(output, dioRuntimePackage, 'value_response.dart'),
    );
    expect(
      operation,
      contains(
        'Future<TonikResult<String, Response<Object?>>> call({ '
        'TonikCancellation? cancellation',
      ),
    );
    final api = normalizeGeneratedSource(
      File(
        path.join(
          output.path,
          dioRuntimePackage,
          'lib/src/api_client/examples_api.dart',
        ),
      ).readAsStringSync(),
    );
    expect(
      api,
      contains(
        'Future<TonikResult<String, Response<Object?>>> '
        'valueResponse({TonikCancellation? cancellation}) async => '
        '_valueResponse(cancellation: cancellation)',
      ),
    );
    expect(api, contains('ValueResponse(server.baseUrl, () => server.dio)'));
    final server = normalizeGeneratedSource(
      File(
        path.join(output.path, dioRuntimePackage, 'lib/src/server/server.dart'),
      ).readAsStringSync(),
    );
    expect(server, contains('sealed class Server'));
    expect(server, contains('final String baseUrl'));
    expect(server, contains('Dio get dio'));
    expect(server, contains('void close()'));

    await generateExecutionPackage(
      output,
      package: httpRuntimePackage,
      backend: TransportBackend.http,
    );
    final httpApi = normalizeGeneratedSource(
      File(
        path.join(
          output.path,
          httpRuntimePackage,
          'lib/src/api_client/examples_api.dart',
        ),
      ).readAsStringSync(),
    );
    expect(
      httpApi,
      contains(
        'Future<TonikResult<String, Response>> valueResponse({ '
        'TonikCancellation? cancellation, }) async => '
        '_valueResponse(cancellation: cancellation)',
      ),
    );
    expect(
      httpApi,
      contains('ValueResponse(server.baseUrl, () => server.client)'),
    );
    final httpServer = normalizeGeneratedSource(
      File(
        path.join(
          output.path,
          httpRuntimePackage,
          'lib/src/server/server.dart',
        ),
      ).readAsStringSync(),
    );
    expect(httpServer, contains('Client get client'));
    expect(httpServer, contains('void close()'));
  });

  test(
    'synchronous call forwards closures without async preparation',
    () async {
      await generateExecutionPackage(
        output,
        package: dioRuntimePackage,
        backend: TransportBackend.dio,
      );
      final source = normalizeGeneratedSource(
        operationSource(output, dioRuntimePackage, 'value_response.dart'),
      );
      final callBody = source.substring(
        source.indexOf(' call('),
        source.indexOf('List<String> _path('),
      );
      expect(callBody, contains('execute('));
      expect(
        callBody,
        contains(
          'prepare: () => DioOperationRequest( path: _path(), query: null, '
          'data: _data(), options: _options(), )',
        ),
      );
      expect(callBody, contains('decode: _parseResponse'));
      expect(callBody, isNot(contains('prepare: () async')));
      expect(callBody, isNot(contains('Future.sync')));
    },
  );

  test(
    'multipart call uses only the explicit async preparation path',
    () async {
      await generateExecutionPackage(
        output,
        package: httpRuntimePackage,
        backend: TransportBackend.http,
      );
      final source = normalizeGeneratedSource(
        operationSource(output, httpRuntimePackage, 'multipart_request.dart'),
      );
      expect(source, contains('executeVoidAsync('));
      expect(source, contains('prepare: () async => HttpOperationRequest('));
      expect(source, contains('data: await _data(body: body)'));
    },
  );

  for (final responseCase in const [
    ('value', 'value_response.dart', 'String'),
    ('void', 'void_response.dart', 'void'),
    ('Never', 'never_response.dart', 'Never'),
    ('Never nullable', 'nullable_never_response.dart', 'Never?'),
    ('no response', 'no_declared_response.dart', 'void'),
  ]) {
    test(
      '${responseCase.$1} response retains its public result type',
      () async {
        await generateExecutionPackage(
          output,
          package: dioRuntimePackage,
          backend: TransportBackend.dio,
        );
        final source = normalizeGeneratedSource(
          operationSource(output, dioRuntimePackage, responseCase.$2),
        );
        expect(source, contains('TonikResult<${responseCase.$3},'));
        expect(
          source.substring(source.indexOf(' call(')),
          isNot(contains(' as ')),
        );
      },
    );
  }

  test('generated package compiles under the core-prefix allocator', () async {
    final packageRoot = await prepareRuntimePackage(
      package: dioRuntimePackage,
      backend: TransportBackend.dio,
      probeAsset: path.join(
        operationTestDirectory,
        'support/empty_probe.dart.txt',
      ),
    );
    addTearDown(() => packageRoot.parent.deleteSync(recursive: true));
    final analysis = await runDart(packageRoot, const [
      'analyze',
      '--fatal-infos',
    ]);
    expect(
      analysis.exitCode,
      0,
      reason: '${analysis.stdout}\n${analysis.stderr}',
    );
  });

  test(
    'generated HTTP package compiles under the core-prefix allocator',
    () async {
      final packageRoot = await prepareRuntimePackage(
        package: httpRuntimePackage,
        backend: TransportBackend.http,
        probeAsset: path.join(
          operationTestDirectory,
          'support/empty_probe.dart.txt',
        ),
      );
      addTearDown(() => packageRoot.parent.deleteSync(recursive: true));
      final analysis = await runDart(packageRoot, const [
        'analyze',
        '--fatal-infos',
      ]);
      expect(
        analysis.exitCode,
        0,
        reason: '${analysis.stdout}\n${analysis.stderr}',
      );
    },
  );

  test(
    'inherited execution names cannot shadow operation parameters',
    () async {
      final context = Context.initial();
      final parameters = {
        for (final name in [
          'execute',
          'path',
          'data',
          'options',
          'prepare',
          'decode',
          'parseResponse',
        ])
          QueryParameterObject(
            name: name,
            rawName: name,
            description: null,
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: true,
            model: StringModel(context: context.push(name)),
            encoding: QueryParameterEncoding.form,
            context: context.push(name),
            examples: const [],
            defaultValue: null,
          ),
      };
      final shadowDocument = document(
        context,
        operations: {
          operation(
            context,
            operationId: 'shadowInheritedNames',
            responseModel: StringModel(context: context),
            queryParameters: parameters,
          ),
        },
      );
      await generateExecutionPackage(
        output,
        package: dioRuntimePackage,
        backend: TransportBackend.dio,
        document: shadowDocument,
      );
      final packageRoot = Directory(path.join(output.path, dioRuntimePackage));
      final pubspec = File(path.join(packageRoot.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync(
        '${pubspec.readAsStringSync()}\ndependency_overrides:\n'
        '  tonik_util:\n'
        "    path: ${path.join(repositoryRoot, 'packages', 'tonik_util')}\n",
      );
      final get = await runDart(packageRoot, const ['pub', 'get', '--offline']);
      expect(get.exitCode, 0, reason: '${get.stdout}\n${get.stderr}');
      final analysis = await runDart(packageRoot, const [
        'analyze',
        '--fatal-infos',
      ]);
      expect(
        analysis.exitCode,
        0,
        reason: '${analysis.stdout}\n${analysis.stderr}',
      );
    },
  );

  for (final collisionCase in const [
    (
      TransportBackend.dio,
      'dio_collision_api',
      'dioOperation',
      'dioOperationBase',
      'DioOperation',
      'dio_operation_base_base.dart',
      'dio_operation.dart',
      'dio_operation_base.dart',
    ),
    (
      TransportBackend.http,
      'http_collision_api',
      'httpOperation',
      'httpOperationBase',
      'HttpOperation',
      'http_operation_base_base.dart',
      'http_operation.dart',
      'http_operation_base.dart',
    ),
  ]) {
    test(
      '${collisionCase.$5} repeatedly resolves base filename collisions',
      () async {
        final context = Context.initial();
        await generateExecutionPackage(
          output,
          package: collisionCase.$2,
          backend: collisionCase.$1,
          document: document(
            context,
            operations: {
              operation(context, operationId: collisionCase.$3),
              operation(context, operationId: collisionCase.$4),
            },
          ),
        );
        final operationDirectory = Directory(
          path.join(output.path, collisionCase.$2, 'lib/src/operation'),
        );
        final files = operationDirectory.listSync().whereType<File>().toList();
        expect(
          files.where(
            (file) =>
                file.readAsStringSync().contains('class ${collisionCase.$5}<'),
          ),
          hasLength(1),
        );
        expect(
          files.where(
            (file) =>
                file.readAsStringSync().contains('class ${collisionCase.$5} '),
          ),
          hasLength(1),
        );
        expect(
          File(path.join(operationDirectory.path, collisionCase.$6)),
          exists,
        );
        for (final operationFilename in [collisionCase.$7, collisionCase.$8]) {
          expect(
            operationSource(output, collisionCase.$2, operationFilename),
            contains(
              'package:${collisionCase.$2}/src/operation/${collisionCase.$6}',
            ),
          );
        }

        final packageRoot = Directory(path.join(output.path, collisionCase.$2));
        final pubspec = File(path.join(packageRoot.path, 'pubspec.yaml'));
        pubspec.writeAsStringSync(
          '${pubspec.readAsStringSync()}\ndependency_overrides:\n'
          '  tonik_util:\n'
          "    path: ${path.join(repositoryRoot, 'packages', 'tonik_util')}\n",
        );
        final get = await runDart(packageRoot, const [
          'pub',
          'get',
          '--offline',
        ]);
        expect(get.exitCode, 0, reason: '${get.stdout}\n${get.stderr}');
        final analysis = await runDart(packageRoot, const [
          'analyze',
          '--fatal-infos',
        ]);
        expect(
          analysis.exitCode,
          0,
          reason: '${analysis.stdout}\n${analysis.stderr}',
        );

        await generateExecutionPackage(
          output,
          package: collisionCase.$2,
          backend: collisionCase.$1,
        );
        final regeneratedFilenames = operationDirectory
            .listSync()
            .whereType<File>()
            .map((file) => path.basename(file.path))
            .toSet();
        expect(
          regeneratedFilenames,
          contains(
            collisionCase.$1 == TransportBackend.dio
                ? 'dio_operation.dart'
                : 'http_operation.dart',
          ),
        );
        expect(regeneratedFilenames, isNot(contains(collisionCase.$6)));
      },
    );
  }

  test('in-place backend switching removes the stale backend base', () async {
    await generateExecutionPackage(
      output,
      package: 'switch_api',
      backend: TransportBackend.dio,
    );
    final operationDir = Directory(
      path.join(output.path, 'switch_api', 'lib/src/operation'),
    );
    final handwrittenBaseLikeFile = File(
      path.join(operationDir.path, 'dio_operation_base.dart'),
    )..writeAsStringSync('// Handwritten file.\n');
    await generateExecutionPackage(
      output,
      package: 'switch_api',
      backend: TransportBackend.http,
    );
    expect(handwrittenBaseLikeFile, exists);
    final sources = operationDir
        .listSync()
        .whereType<File>()
        .map((file) => file.readAsStringSync())
        .toList();
    expect(
      sources.where((source) => source.contains('class HttpOperation<')),
      hasLength(1),
    );
    expect(
      sources.any((source) => source.contains('class DioOperation<')),
      isFalse,
    );
  });

  test('obsolete dispatch APIs have no repository callers', () {
    final packageRoot = Directory(
      path.join(repositoryRoot, 'packages', 'tonik_generate'),
    );
    final removedApi = ['generate', 'Dispatch', 'Statements'].join();
    final stale = packageRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => path.extension(file.path) == '.dart')
        .where((file) => file.readAsStringSync().contains(removedApi))
        .map((file) => path.relative(file.path, from: repositoryRoot))
        .toList();
    expect(stale, isEmpty, reason: 'stale dispatch API callers: $stale');
  });

  test('core and util production dependencies remain transport-free', () {
    for (final package in ['tonik_core', 'tonik_util']) {
      final root = path.join(repositoryRoot, 'packages', package);
      final imports = Directory(path.join(root, 'lib'))
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => path.extension(file.path) == '.dart')
          .where(
            (file) => RegExp(
              "^import 'package:(dio|http)/",
              multiLine: true,
            ).hasMatch(file.readAsStringSync()),
          )
          .toList();
      expect(imports, isEmpty);
      final pubspecLines = File(
        path.join(root, 'pubspec.yaml'),
      ).readAsLinesSync();
      final dependenciesStart = pubspecLines.indexOf('dependencies:');
      final devDependenciesStart = pubspecLines.indexOf('dev_dependencies:');
      final dependencyNames = pubspecLines
          .sublist(dependenciesStart + 1, devDependenciesStart)
          .map((line) => RegExp('^  ([^ :]+):').firstMatch(line)?.group(1))
          .whereType<String>()
          .toSet();
      expect(dependencyNames.intersection({'dio', 'http'}), isEmpty);
    }
  });

  test('focused inheritance evidence remains split by concern', () {
    final files = Directory(operationTestDirectory)
        .listSync()
        .whereType<File>()
        .map((file) => path.basename(file.path))
        .where(
          (name) => name.contains('operation_') && name.endsWith('_test.dart'),
        )
        .toSet();
    expect(files, contains('operation_execution_structure_test.dart'));
    expect(files, contains('dio_operation_runtime_test.dart'));
    expect(files, contains('http_operation_runtime_test.dart'));
    expect(files, isNot(contains('operation_execution_inheritance_test.dart')));
  });

  test('focused generation exercises every modified generator path', () async {
    final requiredSources = [
      'generator.dart',
      'operation/operation_base_file_generator.dart',
      'operation/operation_base_generator.dart',
      'operation/operation_file_generator.dart',
      'operation/operation_generator.dart',
      'transport/dio_backend_generator.dart',
      'transport/http_backend_generator.dart',
      'transport/transport_backend_generator.dart',
      'transport/transport_backend_generator_factory.dart',
    ];
    final generatorRoot = path.join(
      repositoryRoot,
      'packages',
      'tonik_generate',
      'lib',
      'src',
    );
    for (final source in requiredSources) {
      expect(File(path.join(generatorRoot, source)), exists, reason: source);
    }
    await generateExecutionPackage(
      output,
      package: dioRuntimePackage,
      backend: TransportBackend.dio,
    );
    await generateExecutionPackage(
      output,
      package: httpRuntimePackage,
      backend: TransportBackend.http,
    );
    expect(
      operationSource(output, dioRuntimePackage, 'dio_operation.dart'),
      contains('abstract base class DioOperation<T>'),
    );
    expect(
      operationSource(output, httpRuntimePackage, 'http_operation.dart'),
      contains('abstract base class HttpOperation<T>'),
    );
  });

  test('production source keeps executor composition out of scope', () {
    final production =
        Directory(path.join(repositoryRoot, 'packages/tonik_generate/lib'))
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => path.extension(file.path) == '.dart')
            .map((file) => file.readAsStringSync())
            .join('\n');
    expect(production, isNot(contains('OperationExecutor')));
  });
}

final Matcher exists = const TypeMatcher<File>().having(
  (file) => file.existsSync(),
  'exists',
  isTrue,
);
