// Generated public choice names exceed the line limit.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:multipart_style_api/multipart_style_api.dart' as api;
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('styled nested arrays fail before sending on both backends', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postStyleNestedArrays(
      body: const api.NestedArrayForm(
        values: [
          [1, 2],
        ],
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('styled file values fail before sending on both backends', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postStyleFileValues(
      body: const api.MultipartStyleFileValuesPostBodyBodyModel(
        file: TonikFileBytes([1, 2]),
        encoded: TonikFileBytes([3, 4]),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('styled typed maps use raw array, date, and enum text', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postStyleTypedMapValues(
      body: api.MultipartStyleTypedMapValuesPostBodyBodyModel(
        metadata: const {
          'tags': ['a/b', 'x y'],
        },
        entries: const [
          {
            'colors': ['red', 'blue'],
          },
        ],
        timestamps: {'created': DateTime.utc(2026, 10, 18, 12, 30)},
        statuses: const {
          'state':
              api.MultipartStyleTypedMapValuesPostBodyBodyStatusesMapModel.open,
        },
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(4));
    expect(wire.single('tags').bodyBytes, utf8.encode('a/b,x y'));
    expect(wire.single('colors').bodyBytes, utf8.encode('red,blue'));
    expect(
      wire.single('created').bodyBytes,
      utf8.encode('2026-10-18T12:30:00.000Z'),
    );
    expect(wire.single('state').bodyBytes, utf8.encode('open'));
    expect(wire.single('tags').contentType, 'text/plain; charset=utf-8');
    expect(wire.single('colors').contentType, 'text/plain; charset=utf-8');
    expect(wire.single('created').contentType, 'text/plain; charset=utf-8');
    expect(wire.single('state').contentType, 'text/plain; charset=utf-8');
    expect(
      wire.single('tags').header('content-disposition'),
      contains('name="tags"'),
    );
    expect(
      wire.single('colors').header('content-disposition'),
      contains('name="colors"'),
    );
  });

  test('non-exploded untyped array sends one raw text part', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postStyleUntypedCollapsed(
      body: const api.MultipartStyleUntypedCollapsedPostBodyBodyModel(
        labels: ['a/b', 'x y'],
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(1));
    final part = wire.single('labels');
    expect(part.bodyBytes, utf8.encode('a/b,x y'));
    expect(part.contentType, startsWith('text/plain'));
    expect(part.header('content-disposition'), contains('name="labels"'));
  });

  test(
    'non-exploded untyped array rejects a complex item before send',
    () async {
      final server = await RawRequestServer.start();
      final client = api.MultipartApi(
        api.CustomServer(
          baseUrl: server.baseUrl,
          serverConfig: testServerConfig(),
        ),
      );

      final response = await client.postStyleUntypedCollapsed(
        body: const api.MultipartStyleUntypedCollapsedPostBodyBodyModel(
          labels: [
            'a/b',
            {'nested': 'value'},
          ],
        ),
      );

      final error = requireError(response);
      expect(error.type, TonikErrorType.encoding);
      expect(server.requestCount, 0);
    },
  );

  test('styled allOf map merges values into expanded text parts', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postStyleMergedMap(
      body: const api.MultipartStyleMergedMapPostBodyBodyAllOfModel(
        multipartStyleMergedMapPostBodyBodyAllOfModel2:
            api.MultipartStyleMergedMapPostBodyBodyAllOfModel2(
              metadata: {'topic': 'a/b'},
              labels: {
                'first': ['a/b', 'x y'],
              },
            ),
        multipartStyleMergedMapPostBodyBodyAllOfModel3:
            api.MultipartStyleMergedMapPostBodyBodyAllOfModel3(
              metadata: {'note': 'x y'},
              labels: {
                'second': ['café', 'ü'],
              },
            ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(4));
    expect(wire.single('topic').bodyBytes, utf8.encode('a/b'));
    expect(wire.single('note').bodyBytes, utf8.encode('x y'));
    expect(wire.single('first').bodyBytes, utf8.encode('a/b,x y'));
    expect(wire.single('second').bodyBytes, utf8.encode('café,ü'));
    expect(wire.single('topic').contentType, startsWith('text/plain'));
    expect(wire.single('note').contentType, startsWith('text/plain'));
    expect(wire.single('first').contentType, 'text/plain; charset=utf-8');
    expect(wire.single('second').contentType, 'text/plain; charset=utf-8');
    expect(
      wire.single('topic').header('content-disposition'),
      contains('name="topic"'),
    );
    expect(
      wire.single('note').header('content-disposition'),
      contains('name="note"'),
    );
  });

  test(
    'styled maps expand per item and untyped scalar uses raw text',
    () async {
      final server = await RawRequestServer.start();
      final client = api.MultipartApi(
        api.CustomServer(
          baseUrl: server.baseUrl,
          serverConfig: testServerConfig(),
        ),
      );

      final response = await client.postStyleMapValues(
        body: const api.MultipartStyleMapValuesPostBodyBodyModel(
          metadata: {'topic': 'a/b', 'note': 'x y'},
          entries: [
            {'first': 'a/b'},
            {'second': 'x y'},
          ],
          loose: 'a/b x',
        ),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts, hasLength(5));
      expect(wire.single('topic').bodyBytes, utf8.encode('a/b'));
      expect(wire.single('note').bodyBytes, utf8.encode('x y'));
      expect(wire.single('first').bodyBytes, utf8.encode('a/b'));
      expect(wire.single('second').bodyBytes, utf8.encode('x y'));
      expect(wire.single('loose').bodyBytes, utf8.encode('a/b x'));
      expect(wire.single('topic').contentType, startsWith('text/plain'));
      expect(wire.single('note').contentType, startsWith('text/plain'));
      expect(wire.single('first').contentType, startsWith('text/plain'));
      expect(wire.single('second').contentType, startsWith('text/plain'));
      expect(wire.single('loose').contentType, startsWith('text/plain'));
      expect(
        wire.single('topic').header('content-disposition'),
        contains('name="topic"'),
      );
      expect(
        wire.single('first').header('content-disposition'),
        contains('name="first"'),
      );
    },
  );

  test(
    'styled untyped complex value fails before the request is sent',
    () async {
      final server = await RawRequestServer.start();
      final client = api.MultipartApi(
        api.CustomServer(
          baseUrl: server.baseUrl,
          serverConfig: testServerConfig(),
        ),
      );

      final response = await client.postStyleMapValues(
        body: const api.MultipartStyleMapValuesPostBodyBodyModel(
          metadata: {'topic': 'a/b'},
          entries: [],
          loose: {'nested': 'value'},
        ),
      );

      final error = requireError(response);
      expect(error.type, TonikErrorType.encoding);
      expect(server.requestCount, 0);
    },
  );

  test('styled map collapses into one raw named text part', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postStyleCollapsedMap(
      body: const api.MultipartStyleCollapsedMapPostBodyBodyModel(
        metadata: {'topic': 'a/b', 'note': 'x y'},
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(1));
    final part = wire.single('metadata');
    expect(part.bodyBytes, utf8.encode('topic,a/b,note,x y'));
    expect(part.contentType, startsWith('text/plain'));
    expect(part.header('content-disposition'), contains('name="metadata"'));
  });

  test('style fields expand without URI escaping beside a media choice', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postStyleNamedFields(
      body: const api.MultipartStyleNamedFieldsPostBodyBodyMultipartModel(
        labels: ['café/ü', 'x y'],
        metadata: api.MultipartStyleNamedFieldsPostBodyBodyMetadataModel(
          topic: 'a/b',
          note: 'x y',
        ),
        details: api.MultipartStyleNamedFieldsPostBodyBodyDetailsModel(
          topic: 'a/b',
          note: 'x y',
        ),
        payload:
            api.MultipartStyleNamedFieldsPostBodyBodyPayloadMultipartChoicesPayloadOneOfModelApplicationJsonChoice1(
              'json',
            ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(7));
    final labels = wire.named('labels');
    expect(labels, hasLength(2));
    expect(labels[0].bodyBytes, utf8.encode('café/ü'));
    expect(labels[1].bodyBytes, utf8.encode('x y'));
    expect(labels[0].contentType, 'text/plain; charset=utf-8');
    expect(labels[1].contentType, startsWith('text/plain'));
    expect(labels[0].header('content-disposition'), contains('name="labels"'));
    expect(labels[1].header('content-disposition'), contains('name="labels"'));
    expect(wire.single('topic').bodyBytes, utf8.encode('a/b'));
    expect(wire.single('note').bodyBytes, utf8.encode('x y'));
    expect(wire.single('topic').contentType, startsWith('text/plain'));
    expect(wire.single('note').contentType, startsWith('text/plain'));
    expect(
      wire.single('topic').header('content-disposition'),
      contains('name="topic"'),
    );
    expect(
      wire.single('note').header('content-disposition'),
      contains('name="note"'),
    );
    expect(wire.single('details[topic]').bodyBytes, utf8.encode('a/b'));
    expect(wire.single('details[note]').bodyBytes, utf8.encode('x y'));
    expect(wire.single('details[topic]').contentType, startsWith('text/plain'));
    expect(wire.single('details[note]').contentType, startsWith('text/plain'));
    expect(
      wire.single('details[topic]').header('content-disposition'),
      contains('name="details[topic]"'),
    );
    expect(
      wire.single('details[note]').header('content-disposition'),
      contains('name="details[note]"'),
    );
    expect(wire.single('payload').bodyBytes, utf8.encode('"json"'));
    expect(wire.single('payload').contentType, startsWith('application/json'));
  });

  test(
    'form style collapses arrays and objects into named text parts',
    () async {
      final server = await RawRequestServer.start();
      final client = api.MultipartApi(
        api.CustomServer(
          baseUrl: server.baseUrl,
          serverConfig: testServerConfig(),
        ),
      );

      final response = await client.postStyleCollapsedFields(
        body: const api.MultipartStyleCollapsedFieldsPostBodyBodyModel(
          labels: ['a/b', 'x y'],
          metadata: api.MultipartStyleCollapsedFieldsPostBodyBodyMetadataModel(
            topic: 'a/b',
            note: 'x y',
          ),
        ),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts, hasLength(2));
      expect(wire.single('labels').bodyBytes, utf8.encode('a/b,x y'));
      expect(wire.single('labels').contentType, startsWith('text/plain'));
      expect(
        wire.single('labels').header('content-disposition'),
        contains('name="labels"'),
      );
      expect(
        wire.single('metadata').bodyBytes,
        utf8.encode('topic,a/b,note,x y'),
      );
      expect(wire.single('metadata').contentType, startsWith('text/plain'));
      expect(
        wire.single('metadata').header('content-disposition'),
        contains('name="metadata"'),
      );
    },
  );
}
