import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/operation_base_file_generator.dart';
import 'package:tonik_generate/src/operation/operation_base_generator.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/transport/http_backend_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator_factory.dart';

void main() {
  test('ordinary Dio base owns the shared request helpers', () {
    final specs = transportBackendGeneratorFor(TransportBackend.dio)
        .operationBaseGenerator
        .generate();

    expect(specs.cast<Class>().map((spec) => spec.name), [
      'DioOperation',
      'DioOperationRequest',
      '_DioPreparedRequest',
      '_DioDispatchResult',
    ]);
  });

  test('streaming Dio base emits only its base and dispatch result', () {
    final specs = transportBackendGeneratorFor(TransportBackend.dio)
        .streamingOperationBaseGenerator
        .generate();

    expect(specs.cast<Class>().map((spec) => spec.name), [
      'DioStreamingOperation',
      '_DioStreamingDispatchResult',
    ]);
  });

  test('ordinary HTTP base owns the shared request helpers', () {
    final specs = transportBackendGeneratorFor(TransportBackend.http)
        .operationBaseGenerator
        .generate();

    expect(specs.cast<Class>().map((spec) => spec.name), [
      'HttpOperation',
      'HttpOperationRequest',
      '_HttpPreparedRequest',
      '_HttpDispatchResult',
    ]);
  });

  test('streaming HTTP base emits only its base and dispatch result', () {
    final specs = transportBackendGeneratorFor(TransportBackend.http)
        .streamingOperationBaseGenerator
        .generate();

    expect(specs.cast<Class>().map((spec) => spec.name), [
      'HttpStreamingOperation',
      '_HttpStreamingDispatchResult',
    ]);
  });

  group('file composition', () {
    late Directory tempDir;
    late NameManager nameManager;
    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('operation_base_file_');
      nameManager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('writes only the injected ordinary generator by default', () {
      const backend = DioBackendGenerator(
        operationBaseGenerator: _BaseGenerator('OrdinaryOperation'),
        streamingOperationBaseGenerator: _BaseGenerator('StreamingOperation'),
      );
      final generator = OperationBaseFileGenerator(
        operationBaseGenerator: backend.operationBaseGenerator,
        streamingOperationBaseGenerator:
            backend.streamingOperationBaseGenerator,
        operationBaseFilename: 'operation.dart',
        nameManager: nameManager,
      );
      final filename = generator.writeFile(
        outputDirectory: tempDir.path,
        package: 'api',
      );

      expect(filename, 'lib/src/operation/operation.dart');
      final source = File(path.join(tempDir.path, 'api', filename))
          .readAsStringSync();
      expect(
        format(source),
        format('''
// Generated code - do not modify by hand

class OrdinaryOperation {}
'''),
      );
    });

    test('appends the injected streaming generator when requested', () {
      const backend = HttpBackendGenerator(
        operationBaseGenerator: _BaseGenerator('OrdinaryOperation'),
        streamingOperationBaseGenerator: _BaseGenerator('StreamingOperation'),
      );
      final generator = OperationBaseFileGenerator(
        operationBaseGenerator: backend.operationBaseGenerator,
        streamingOperationBaseGenerator:
            backend.streamingOperationBaseGenerator,
        operationBaseFilename: 'operation.dart',
        nameManager: nameManager,
      );
      final filename = generator.writeFile(
        outputDirectory: tempDir.path,
        package: 'api',
        includeStreaming: true,
      );

      expect(filename, 'lib/src/operation/operation.dart');
      final source = File(path.join(tempDir.path, 'api', filename))
          .readAsStringSync();
      expect(
        format(source),
        format('''
// Generated code - do not modify by hand

class OrdinaryOperation {}

class StreamingOperation {}
'''),
      );
    });
  });
}

final class const _BaseGenerator(@override final String className)
    implements OperationBaseGenerator {
  @override
  Iterable<Spec> generate() => [Class((builder) => builder..name = className)];

  @override
  String get filename => throw UnimplementedError();

  @override
  String get clientConstructorParameterName => throw UnimplementedError();

  @override
  Reference baseType({
    required String package,
    required Reference valueType,
    String? filename,
    bool streaming = false,
  }) => throw UnimplementedError();

  @override
  Expression executionInvocation({
    required String package,
    required String filename,
    required OperationRequestPlan plan,
    required Expression path,
    required Expression queryParameters,
    required Expression data,
    required Expression options,
    required Expression? decode,
    required bool isVoid,
    required bool isDataAsync,
    bool streaming = false,
  }) => throw UnimplementedError();
}
