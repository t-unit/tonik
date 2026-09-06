import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';
import 'package:tonik_generate/src/operation/operation_base_generator.dart';

const _packageName = 'test_package';

void main() {
  group('operation base filename', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'operation_base_filename_',
      );
    });

    tearDown(() {
      tempDirectory.deleteSync(recursive: true);
    });

    for (final backend in TransportBackend.values) {
      final details = _detailsFor(backend);

      test('$backend resolves a default filename collision', () async {
        final operation = _operation(details.baseClassName);

        await const Generator().generate(
          apiDocument: _document({operation}),
          outputDirectory: tempDirectory.path,
          package: _packageName,
          config: TonikConfig(transport: TransportConfig(backend: backend)),
        );

        final expectedBaseFilename = '${details.filenameStem}_base.dart';
        final operationDirectory = _operationDirectory(tempDirectory);
        expect(
          File(path.join(operationDirectory.path, expectedBaseFilename))
              .existsSync(),
          isTrue,
        );
        _expectOperationUsesBase(
          file: File(
            path.join(operationDirectory.path, details.defaultFilename),
          ),
          details: details,
          baseFilename: expectedBaseFilename,
        );
      });

      test(
        '$backend resolves once and shares multiple-collision filename',
        () async {
          final operations = {
            _operation(details.baseClassName),
            _operation('${details.baseClassName}Base'),
            _operation('${details.baseClassName}BaseBase'),
            _operation('RegularOperation'),
          };
          var resolutionCount = 0;

          await const Generator().generate(
            apiDocument: _document(operations),
            outputDirectory: tempDirectory.path,
            package: _packageName,
            config: TonikConfig(transport: TransportConfig(backend: backend)),
            operationBaseFilenameResolver:
                ({required generator, required operationFilenames}) {
                  resolutionCount++;
                  return operationBaseFilename(
                    generator: generator,
                    operationFilenames: operationFilenames,
                  );
                },
          );

          expect(resolutionCount, 1);
          final expectedBaseFilename =
              '${details.filenameStem}_base_base_base.dart';
          final operationDirectory = _operationDirectory(tempDirectory);
          expect(
            File(path.join(operationDirectory.path, expectedBaseFilename))
                .existsSync(),
            isTrue,
          );

          for (final operation in operations) {
            final className = operation.operationId!;
            final filename = _filenameForClass(className);
            _expectOperationUsesBase(
              file: File(path.join(operationDirectory.path, filename)),
              details: details,
              baseFilename: expectedBaseFilename,
            );
          }
        },
      );

      test('$backend writes the default base for an empty document', () async {
        await const Generator().generate(
          apiDocument: _document(const {}),
          outputDirectory: tempDirectory.path,
          package: _packageName,
          config: TonikConfig(transport: TransportConfig(backend: backend)),
        );

        expect(
          _operationDirectory(tempDirectory)
              .listSync()
              .whereType<File>()
              .map((file) => path.basename(file.path)),
          [details.defaultFilename],
        );
      });
    }

    test(
      'removes stale generated bases without deleting colliding operations',
      () async {
        const backend = TransportBackend.http;
        final details = _detailsFor(backend);
        final operations = {
          _operation(details.baseClassName),
          _operation('${details.baseClassName}Base'),
        };
        final operationDirectory = _operationDirectory(tempDirectory)
          ..createSync(recursive: true);
        final staleGenerated =
            File(
              path.join(
                operationDirectory.path,
                'http_operation_base_base_base.dart',
              ),
            )..writeAsStringSync(
              '// Generated code - do not modify by hand\n\nfinal stale = true;\n',
            );
        final handwritten = File(
          path.join(
            operationDirectory.path,
            'http_operation_base_base_base_base.dart',
          ),
        )..writeAsStringSync('final handwritten = true;\n');

        await const Generator().generate(
          apiDocument: _document(operations),
          outputDirectory: tempDirectory.path,
          package: _packageName,
          config: const TonikConfig(
            transport: TransportConfig(backend: backend),
          ),
        );

        expect(staleGenerated.existsSync(), isFalse);
        expect(handwritten.existsSync(), isTrue);
        expect(
          File(path.join(operationDirectory.path, 'http_operation.dart'))
              .existsSync(),
          isTrue,
        );
        expect(
          File(path.join(operationDirectory.path, 'http_operation_base.dart'))
              .existsSync(),
          isTrue,
        );
        expect(
          File(
            path.join(operationDirectory.path, 'http_operation_base_base.dart'),
          ).existsSync(),
          isTrue,
        );
      },
    );

    test('repeated generation is byte-identical', () async {
      final document = _document({
        _operation('DioOperation'),
        _operation('DioOperationBase'),
        _operation('FetchWidgets'),
      });

      await const Generator().generate(
        apiDocument: document,
        outputDirectory: tempDirectory.path,
        package: _packageName,
      );
      final first = _packageFiles(tempDirectory);

      await const Generator().generate(
        apiDocument: document,
        outputDirectory: tempDirectory.path,
        package: _packageName,
      );
      final second = _packageFiles(tempDirectory);

      expect(second, first);
    });
  });
}

({String baseClassName, String defaultFilename, String filenameStem})
_detailsFor(TransportBackend backend) => switch (backend) {
  TransportBackend.dio => (
    baseClassName: 'DioOperation',
    defaultFilename: 'dio_operation.dart',
    filenameStem: 'dio_operation',
  ),
  TransportBackend.http => (
    baseClassName: 'HttpOperation',
    defaultFilename: 'http_operation.dart',
    filenameStem: 'http_operation',
  ),
};

Operation _operation(String operationId) => Operation(
  operationId: operationId,
  context: Context.initial(),
  path: '/widgets',
  method: HttpMethod.get,
  tags: const {},
  isDeprecated: false,
  headers: const {},
  queryParameters: const {},
  pathParameters: const {},
  cookieParameters: const {},
  responses: const {},
  securitySchemes: const {},
);

ApiDocument _document(Set<Operation> operations) => ApiDocument(
  title: 'Test',
  version: '1.0.0',
  models: const {},
  responseHeaders: const {},
  requestHeaders: const {},
  servers: const {},
  operations: operations,
  responses: const <Response>{},
  queryParameters: const {},
  pathParameters: const {},
  cookieParameters: const {},
  requestBodies: const {},
);

Directory _operationDirectory(Directory root) =>
    Directory(path.join(root.path, _packageName, 'lib', 'src', 'operation'));

String _filenameForClass(String className) {
  final snakeCase = className
      .replaceAllMapped(RegExp('(?<=[a-z0-9])(?=[A-Z])'), (_) => '_')
      .toLowerCase();
  return '$snakeCase.dart';
}

void _expectOperationUsesBase({
  required File file,
  required ({String baseClassName, String defaultFilename, String filenameStem})
  details,
  required String baseFilename,
}) {
  final content = file.readAsStringSync();
  final expectedUri = 'package:$_packageName/src/operation/$baseFilename';
  final operationBaseImports = RegExp(
    "^import '(package:$_packageName/src/operation/"
    "${RegExp.escape(details.filenameStem)}(?:_base)*\\.dart)'"
    r'\s*as (_i\d+);$',
    multiLine: true,
  ).allMatches(content).toList();

  expect(operationBaseImports, hasLength(1));
  expect(operationBaseImports.single.group(1), expectedUri);
  final prefix = operationBaseImports.single.group(2)!;

  final baseReferences = RegExp(
    '${RegExp.escape(prefix)}\\.'
    '${RegExp.escape(details.baseClassName)}(?:Request)?',
  ).allMatches(content).map((match) => match.group(0)).toList();
  expect(baseReferences, [
    '$prefix.${details.baseClassName}',
    '$prefix.${details.baseClassName}Request',
  ]);
}

Map<String, List<int>> _packageFiles(Directory root) {
  final packageDirectory = Directory(path.join(root.path, _packageName));
  return {
    for (final file
        in packageDirectory.listSync(recursive: true).whereType<File>())
      path.relative(file.path, from: packageDirectory.path): file
          .readAsBytesSync(),
  };
}
