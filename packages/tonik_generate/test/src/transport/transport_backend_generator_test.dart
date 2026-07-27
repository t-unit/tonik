import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/transport/http_backend_generator.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator_factory.dart';

void main() {
  group('transportBackendGeneratorFor', () {
    test('selects the Dio strategy with exact backend metadata', () {
      final backend = transportBackendGeneratorFor(TransportBackend.dio);

      expect(backend, isA<DioBackendGenerator>());
      expect(backend.dependencies, [
        const DependencyDescriptor(name: 'dio', versionConstraint: '^5.8.0+1'),
      ]);
      expect(backend.nativeClientType.symbol, 'Dio');
      expect(backend.nativeClientType.url, 'package:dio/dio.dart');
      expect(backend.nativeResponseType.symbol, 'Response');
      expect(backend.nativeResponseType.url, 'package:dio/dio.dart');
      expect(backend.nativeResponseType.types.single.symbol, 'Object');
      expect(
        backend.nativeResponseType.types.single,
        isA<TypeReference>().having(
          (type) => type.isNullable,
          'isNullable',
          isTrue,
        ),
      );
    });

    test('selects the http strategy with exact backend metadata', () {
      final backend = transportBackendGeneratorFor(TransportBackend.http);

      expect(backend, isA<HttpBackendGenerator>());
      expect(backend.dependencies, [
        const DependencyDescriptor(name: 'http', versionConstraint: '^1.6.0'),
      ]);
      expect(
        backend.generateClientAdapter,
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('http'),
          ),
        ),
      );
    });
  });
}
