import 'dart:io';

import 'package:test/test.dart';
import 'package:tonik/src/config/cli_config.dart';
import 'package:tonik/src/config/config_loader.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('streaming_config_test_');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('loads streaming targets alongside complete serialization targets', () {
    final file = File('${tempDir.path}/tonik.yaml')
      ..writeAsStringSync('''
contentTypes:
  application/vnd.example.ndjson: ndjson
  "Application/Vnd.Example.Lines; profile=records": jsonl
  application/geo+json-seq: json-seq
  application/vnd.example.events: sse
  application/vnd.example.json: json
''');

    final config = ConfigLoader.load(file.path);

    expect(config.contentTypes, {
      'application/vnd.example.ndjson': StreamingContentType.ndjson,
      'Application/Vnd.Example.Lines; profile=records':
          StreamingContentType.jsonLines,
      'application/geo+json-seq': StreamingContentType.jsonSequence,
      'application/vnd.example.events': StreamingContentType.sse,
      'application/vnd.example.json': ContentType.json,
    });
  });

  test('merge and core conversion preserve streaming mappings', () {
    final file = File('${tempDir.path}/tonik.yaml')
      ..writeAsStringSync('''
contentTypes:
  application/vnd.example.events: sse
  application/jsonl: json-seq
''');

    final config = ConfigLoader.load(file.path)
        .merge(backend: TransportBackend.http, packageName: 'custom_streams')
        .toTonikConfig();

    expect(config.contentTypes, {
      'application/vnd.example.events': StreamingContentType.sse,
      'application/jsonl': StreamingContentType.jsonSequence,
    });
    expect(config.transport.backend, TransportBackend.http);
  });

  test('invalid targets list both complete and streaming options', () {
    final file = File('${tempDir.path}/tonik.yaml')
      ..writeAsStringSync('''
contentTypes:
  application/example: unknown
''');

    expect(
      () => ConfigLoader.load(file.path),
      throwsA(
        isA<ConfigLoaderException>().having(
          (error) => error.message,
          'message',
          'Invalid content type for "application/example": unknown. '
              'Must be one of: json, text, bytes, form, multipart, '
              'ndjson, jsonl, json-seq, sse',
        ),
      ),
    );
  });

  test('streaming formats participate in CLI value semantics', () {
    const config = CliConfig(
      contentTypes: {'application/example': StreamingContentType.ndjson},
    );
    const sameConfig = CliConfig(
      contentTypes: {'application/example': StreamingContentType.ndjson},
    );
    const otherFormat = CliConfig(
      contentTypes: {'application/example': StreamingContentType.sse},
    );

    expect(config, sameConfig);
    expect(config.hashCode, sameConfig.hashCode);
    expect(config == otherFormat, isFalse);
    expect(
      config.toString(),
      contains(
        'contentTypes: {application/example: StreamingContentType.ndjson}',
      ),
    );
  });
}
