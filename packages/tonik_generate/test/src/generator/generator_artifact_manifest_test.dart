import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

const _packageName = 'test_package';
const _manifestFilename = '.tonik-generated-files.json';

void main() {
  group('Generator artifact manifest', () {
    late Directory tempDir;
    late Context context;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('artifact_manifest_');
      context = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('exports only the supported public artifact categories', () async {
      await const Generator().generate(
        apiDocument: _completeDocument(context),
        outputDirectory: tempDir.path,
        package: _packageName,
      );

      expect(_rootExports(tempDir), [
        'src/api_client/users_api.dart',
        'src/model/user.dart',
        'src/request_body/multi_body.dart',
        'src/response/multi_body_response.dart',
        'src/response_wrapper/get_user_response.dart',
        'src/server/server.dart',
      ]);
    });

    test(
      'keeps API clients public while hiding callable operations',
      () async {
        await const Generator().generate(
          apiDocument: _completeDocument(context),
          outputDirectory: tempDir.path,
          package: _packageName,
        );

        final exports = _rootExports(tempDir);
        expect(exports, contains('src/api_client/users_api.dart'));
        expect(exports, isNot(contains('src/operation/get_user.dart')));
      },
    );

    test('writes sorted normalized package-relative artifact paths', () async {
      await const Generator().generate(
        apiDocument: _completeDocument(context),
        outputDirectory: tempDir.path,
        package: _packageName,
      );

      final manifest =
          jsonDecode(_manifestFile(tempDir).readAsStringSync())
              as Map<String, Object?>;
      final files = (manifest['files']! as List<Object?>).cast<String>();

      expect(manifest['version'], 1);
      expect(files, orderedEquals(files.toList()..sort()));
      expect(files, everyElement(isNot(contains(r'\'))));
      expect(files, contains('lib/src/operation/get_user.dart'));
      expect(files, contains('lib/$_packageName.dart'));
    });

    test('produces byte-identical root exports on repeated runs', () async {
      final document = _completeDocument(context);

      await const Generator().generate(
        apiDocument: document,
        outputDirectory: tempDir.path,
        package: _packageName,
      );
      final first = _libraryFile(tempDir).readAsBytesSync();

      await const Generator().generate(
        apiDocument: document,
        outputDirectory: tempDir.path,
        package: _packageName,
      );
      final second = _libraryFile(tempDir).readAsBytesSync();

      expect(second, first);
    });

    test('removes stale generated files and preserves unknown files', () async {
      await const Generator().generate(
        apiDocument: _completeDocument(context),
        outputDirectory: tempDir.path,
        package: _packageName,
      );

      final packageDirectory = path.join(tempDir.path, _packageName);
      final unknownFile = File(
        path.join(packageDirectory, 'lib', 'src', 'user_extension.dart'),
      )..writeAsStringSync('final userExtension = true;\n');
      final staleBackendFile = File(
        path.join(packageDirectory, 'lib', 'src', 'transport', 'dio.dart'),
      );
      staleBackendFile.parent.createSync(recursive: true);
      staleBackendFile.writeAsStringSync('final dioOnly = true;\n');
      _addManifestEntry(tempDir, 'lib/src/transport/dio.dart');

      await const Generator().generate(
        apiDocument: _emptyDocument(),
        outputDirectory: tempDir.path,
        package: _packageName,
      );

      expect(
        File(
          path.join(packageDirectory, 'lib', 'src', 'model', 'user.dart'),
        ).existsSync(),
        isFalse,
      );
      expect(staleBackendFile.existsSync(), isFalse);
      expect(unknownFile.existsSync(), isTrue);
      expect(_rootExports(tempDir), ['src/server/server.dart']);
    });
  });
}

List<String> _rootExports(Directory tempDir) {
  final content = _libraryFile(tempDir).readAsStringSync();
  return RegExp(
    r"^export '([^']+)';$",
    multiLine: true,
  ).allMatches(content).map((match) => match.group(1)!).toList();
}

File _libraryFile(Directory tempDir) => File(
  path.join(tempDir.path, _packageName, 'lib', '$_packageName.dart'),
);

File _manifestFile(Directory tempDir) => File(
  path.join(tempDir.path, _packageName, _manifestFilename),
);

void _addManifestEntry(Directory tempDir, String entry) {
  final manifestFile = _manifestFile(tempDir);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
  final files = (manifest['files']! as List<Object?>).cast<String>()
    ..add(entry)
    ..sort();
  manifest['files'] = files;
  manifestFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
}

ApiDocument _completeDocument(Context context) {
  final multiBodyResponse = ResponseObject(
    name: 'MultiBodyResponse',
    context: context,
    description: 'Multiple response values',
    bodies: {
      ResponseBody(
        model: StringModel(context: context),
        rawContentType: 'application/json',
        contentType: ContentType.json,
        examples: const [],
      ),
      ResponseBody(
        model: StringModel(context: context),
        rawContentType: 'application/problem+json',
        contentType: ContentType.json,
        examples: const [],
      ),
    },
    headers: const {},
  );
  final errorResponse = ResponseObject(
    name: 'ErrorResponse',
    context: context,
    description: 'Error',
    bodies: {
      ResponseBody(
        model: StringModel(context: context),
        rawContentType: 'application/json',
        contentType: ContentType.json,
        examples: const [],
      ),
    },
    headers: const {},
  );
  final operation = Operation(
    operationId: 'getUser',
    context: context,
    summary: 'Get user',
    description: 'Get a user',
    tags: {Tag(name: 'users')},
    isDeprecated: false,
    path: '/users',
    method: HttpMethod.get,
    headers: const {},
    queryParameters: const {},
    pathParameters: const {},
    cookieParameters: const {},
    securitySchemes: const {},
    responses: {
      const ExplicitResponseStatus(statusCode: 200): multiBodyResponse,
      const ExplicitResponseStatus(statusCode: 400): errorResponse,
    },
  );
  final requestBody = RequestBodyObject(
    name: 'MultiBody',
    context: context,
    description: 'Multiple request values',
    isRequired: true,
    content: {
      RequestContent(
        model: StringModel(context: context),
        contentType: ContentType.json,
        rawContentType: 'application/json',
        examples: const [],
      ),
      RequestContent(
        model: StringModel(context: context),
        contentType: ContentType.json,
        rawContentType: 'application/problem+json',
        examples: const [],
      ),
    },
  );

  return ApiDocument(
    title: 'Test',
    version: '1.0.0',
    description: 'Test',
    models: {
      ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
        examples: const [],
      ),
    },
    responseHeaders: const {},
    requestHeaders: const {},
    servers: const {},
    operations: {operation},
    responses: {multiBodyResponse},
    queryParameters: const {},
    pathParameters: const {},
    cookieParameters: const {},
    requestBodies: {requestBody},
  );
}

ApiDocument _emptyDocument() => ApiDocument(
  title: 'Test',
  version: '1.0.0',
  description: 'Test',
  models: const {},
  responseHeaders: const {},
  requestHeaders: const {},
  servers: const {},
  operations: const {},
  responses: const <Response>{},
  queryParameters: const {},
  pathParameters: const {},
  cookieParameters: const {},
  requestBodies: const {},
);
