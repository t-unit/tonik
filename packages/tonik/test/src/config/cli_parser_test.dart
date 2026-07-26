import 'package:test/test.dart';
import 'package:tonik/src/config/cli_config.dart';
import 'package:tonik/src/config/cli_parser.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('CLI backend parser', () {
    test('accepts Dio', () {
      final arguments = buildCliParser().parse(['--backend', 'dio']);

      final config = mergeCliConfig(
        arguments: arguments,
        fileConfig: const CliConfig(
          transport: TransportConfig(backend: TransportBackend.http),
        ),
      );

      expect(config.transport.backend, TransportBackend.dio);
    });

    test('accepts http', () {
      final arguments = buildCliParser().parse(['--backend', 'http']);

      final config = mergeCliConfig(
        arguments: arguments,
        fileConfig: const CliConfig(),
      );

      expect(config.transport.backend, TransportBackend.http);
    });

    test('rejects unknown values', () {
      final parser = buildCliParser();

      expect(
        () => parser.parse(['--backend', 'fetch']),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects case variants', () {
      final parser = buildCliParser();

      expect(
        () => parser.parse(['--backend', 'Dio']),
        throwsA(isA<FormatException>()),
      );
    });

    test('CLI backend overrides YAML backend', () {
      final arguments = buildCliParser().parse(['--backend', 'dio']);

      final config = mergeCliConfig(
        arguments: arguments,
        fileConfig: const CliConfig(
          transport: TransportConfig(backend: TransportBackend.http),
        ),
      );

      expect(config.transport.backend, TransportBackend.dio);
    });

    test('omitted CLI backend preserves YAML backend', () {
      final arguments = buildCliParser().parse([]);

      final config = mergeCliConfig(
        arguments: arguments,
        fileConfig: const CliConfig(
          transport: TransportConfig(backend: TransportBackend.http),
        ),
      );

      expect(config.transport.backend, TransportBackend.http);
    });

    test('omitted CLI and YAML backend defaults to Dio', () {
      final arguments = buildCliParser().parse([]);

      final config = mergeCliConfig(
        arguments: arguments,
        fileConfig: const CliConfig(),
      );

      expect(config.transport.backend, TransportBackend.dio);
    });
  });
}
