import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('TransportConfig', () {
    test('defaults to Dio', () {
      const config = TransportConfig();

      expect(config.backend, TransportBackend.dio);
    });

    test('stores both supported backends', () {
      final configs = TransportBackend.values
          .map((backend) => TransportConfig(backend: backend))
          .toList();

      expect(configs[0].backend, TransportBackend.dio);
      expect(configs[1].backend, TransportBackend.http);
    });

    test('equality includes backend', () {
      const dioConfig = TransportConfig();
      final sameDioConfig = TransportConfig(backend: dioConfig.backend);
      const httpConfig = TransportConfig(backend: TransportBackend.http);

      expect(dioConfig, sameDioConfig);
      expect(dioConfig == httpConfig, isFalse);
    });

    test('hashCode includes backend', () {
      const dioConfig = TransportConfig();
      final sameDioConfig = TransportConfig(backend: dioConfig.backend);
      const httpConfig = TransportConfig(backend: TransportBackend.http);

      expect(dioConfig.hashCode, sameDioConfig.hashCode);
      expect(dioConfig.hashCode, isNot(httpConfig.hashCode));
    });

    test('toString includes backend', () {
      const config = TransportConfig(backend: TransportBackend.http);

      expect(
        config.toString(),
        'TransportConfig{backend: TransportBackend.http}',
      );
    });
  });
}
