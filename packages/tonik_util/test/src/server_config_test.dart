import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('ServerConfig', () {
    test('creates without a client or factory', () {
      const config = ServerConfig<Object>();

      expect(config.client, isNull);
      expect(config.clientFactory, isNull);
    });

    test('stores an injected client', () {
      final client = Object();
      final config = ServerConfig<Object>(client: client);

      expect(config.client, same(client));
      expect(config.clientFactory, isNull);
    });

    test('stores a client factory', () {
      final client = Object();
      Object factory() => client;

      final config = ServerConfig<Object>(clientFactory: factory);

      expect(config.client, isNull);
      expect(config.clientFactory, same(factory));
      expect(config.clientFactory!(), same(client));
    });

    test('asserts that client and clientFactory are mutually exclusive', () {
      expect(
        () => ServerConfig<Object>(
          client: Object(),
          clientFactory: Object.new,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
