import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

const dioRuntimePackage = 'dio_runtime_api';
const httpRuntimePackage = 'http_runtime_api';

Future<void> generateExecutionPackage(
  Directory root, {
  required String package,
  required TransportBackend backend,
  ApiDocument? document,
}) => const Generator().generate(
  apiDocument: document ?? executionDocument(Context.initial()),
  outputDirectory: root.path,
  package: package,
  config: TonikConfig(
    workerCount: 1,
    transport: TransportConfig(backend: backend),
  ),
);

Future<Directory> prepareRuntimePackage({
  required String package,
  required TransportBackend backend,
  required String probeAsset,
}) async {
  final root = Directory.systemTemp.createTempSync('tonik_runtime_probe_');
  await generateExecutionPackage(root, package: package, backend: backend);
  final packageRoot = Directory(path.join(root.path, package));
  final pubspec = File(path.join(packageRoot.path, 'pubspec.yaml'));
  pubspec.writeAsStringSync(
    '${pubspec.readAsStringSync()}\n'
    'dependency_overrides:\n'
    '  tonik_util:\n'
    '    path: ${path.join(repositoryRoot, 'packages', 'tonik_util')}\n',
  );
  final probe = File(path.join(packageRoot.path, 'bin', 'probe.dart'));
  probe.parent.createSync(recursive: true);
  probe.writeAsStringSync(File(probeAsset).readAsStringSync());

  final get = await Process.run(Platform.resolvedExecutable, const [
    'pub',
    'get',
    '--offline',
  ], workingDirectory: packageRoot.path);
  expect(
    get.exitCode,
    0,
    reason: 'generated package pub get failed:\n${get.stdout}\n${get.stderr}',
  );
  return packageRoot;
}

Future<ProcessResult> runDart(Directory packageRoot, List<String> arguments) =>
    Process.run(
      Platform.resolvedExecutable,
      arguments,
      workingDirectory: packageRoot.path,
    );

Future<void> expectRuntimeProbe(Directory packageRoot, String scenario) async {
  final result = await Process.run(Platform.resolvedExecutable, [
    'run',
    'bin/probe.dart',
    scenario,
  ], workingDirectory: packageRoot.path);
  expect(
    result.exitCode,
    0,
    reason:
        'runtime scenario $scenario failed:\n'
        '${result.stdout}\n${result.stderr}',
  );
}

ApiDocument executionDocument(Context context) {
  final multipartBody = RequestBodyObject(
    name: 'UploadBody',
    context: context.push('multipartRequest'),
    description: null,
    isRequired: true,
    content: {
      MultipartRequestContent(
        name: 'UploadBody',
        context: context.pushAll(['multipartRequest', 'body']),
        parts: [
          MultipartPart(
            name: 'label',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
            encoding: const PartEncoding(
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              headers: null,
              style: EncodingStyle.form,
              explode: true,
              allowReserved: false,
            ),
          ),
        ],
        rawContentType: 'multipart/form-data',
        examples: const [],
      ),
    },
  );
  final operations = <Operation>{
    operation(
      context,
      operationId: 'valueResponse',
      responseModel: StringModel(context: context),
    ),
    operation(context, operationId: 'voidResponse', hasEmptyResponse: true),
    operation(
      context,
      operationId: 'neverResponse',
      responseModel: NeverModel(context: context, isNullable: false),
    ),
    operation(
      context,
      operationId: 'nullableNeverResponse',
      responseModel: NeverModel(context: context, isNullable: true),
    ),
    operation(context, operationId: 'noDeclaredResponse'),
    operation(
      context,
      operationId: 'multipartRequest',
      method: HttpMethod.post,
      requestBody: multipartBody,
    ),
  };
  return document(
    context,
    operations: operations,
    requestBodies: {multipartBody},
  );
}

ApiDocument document(
  Context context, {
  required Set<Operation> operations,
  Set<RequestBody> requestBodies = const {},
}) => ApiDocument(
  title: 'Operation inheritance contract',
  version: '1.0.0',
  models: const {},
  responseHeaders: const {},
  requestHeaders: const {},
  servers: const {},
  operations: operations,
  responses: const {},
  queryParameters: const {},
  pathParameters: const {},
  cookieParameters: const {},
  requestBodies: requestBodies,
);

Operation operation(
  Context context, {
  required String operationId,
  Model? responseModel,
  bool hasEmptyResponse = false,
  RequestBody? requestBody,
  HttpMethod method = HttpMethod.get,
  Set<QueryParameter> queryParameters = const {},
}) {
  final responses = <ResponseStatus, Response>{};
  if (responseModel != null || hasEmptyResponse) {
    responses[const ExplicitResponseStatus(statusCode: 200)] = ResponseObject(
      name: null,
      context: context.push(operationId),
      description: '',
      headers: const {},
      bodies: responseModel == null
          ? const {}
          : {
              ResponseBody(
                model: responseModel,
                rawContentType: 'application/json',
                contentType: ContentType.json,
                examples: const [],
              ),
            },
    );
  }
  return Operation(
    operationId: operationId,
    context: context.push(operationId),
    summary: operationId,
    description: operationId,
    tags: {Tag(name: 'examples')},
    isDeprecated: false,
    path: '/$operationId',
    method: requestBody == null ? method : HttpMethod.post,
    requestBody: requestBody,
    headers: const {},
    queryParameters: queryParameters,
    pathParameters: const {},
    cookieParameters: const {},
    securitySchemes: const {},
    responses: responses,
  );
}

String operationSource(Directory root, String package, String filename) => File(
  path.join(root.path, package, 'lib', 'src', 'operation', filename),
).readAsStringSync();

String normalizeGeneratedSource(String source) => source
    .replaceAll(RegExp(r'\b_i\d+\.'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String get repositoryRoot {
  var directory = Directory.current.absolute;
  while (!File(path.join(directory.path, 'pubspec.yaml')).existsSync() ||
      !Directory(
        path.join(directory.path, 'packages', 'tonik_generate'),
      ).existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Could not locate the repository root.');
    }
    directory = parent;
  }
  return directory.path;
}

String get operationTestDirectory => path.join(
  repositoryRoot,
  'packages',
  'tonik_generate',
  'test',
  'src',
  'operation',
);
