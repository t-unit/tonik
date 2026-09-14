import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late RawRequestServer server;
  late MultipartApi api;
  setUp(() async {
    server = await RawRequestServer.start();
    api = MultipartApi(CustomServer(baseUrl: server.baseUrl));
  });

  test(
    'sends a map typedef in insertion order including an empty string',
    () async {
      // The annotation checks the generated typedef remains assignable.
      // ignore: omit_local_variable_types
      const DynamicStrings body = {
        'second': 'beta',
        'first': 'alpha',
        'empty': '',
      };
      expect(await api.postDynamicStrings(body: body), isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), ['second', 'first', 'empty']);
      expect(wire.parts.map((p) => p.bodyText), ['beta', 'alpha', '']);
      expect(wire.single('first').contentType, startsWith('text/plain'));
      expect(wire.single('empty').filename, isNull);
    },
  );

  test('accepts the direct Map API for an inline root schema', () async {
    expect(
      await api.postDynamicInline(body: {'first': 'alpha'}),
      isTonikSuccess,
    );
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.single.name, 'first');
    expect(wire.parts.single.bodyText, 'alpha');
    expect(wire.parts.single.contentType, startsWith('text/plain'));
  });

  test('omits null map values while retaining later entries', () async {
    expect(
      await api.postDynamicNullableValues(
        body: {'absent': null, 'present': 'value'},
      ),
      isTonikSuccess,
    );
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((p) => p.name), ['present']);
    expect(wire.single('present').bodyText, 'value');
  });

  test('serializes object values as individual JSON parts', () async {
    expect(
      await api.postDynamicObjects(
        body: {
          'one': const ObjectArrayItem(name: 'alpha'),
          'two': const ObjectArrayItem(name: 'beta'),
        },
      ),
      isTonikSuccess,
    );
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((p) => p.name), ['one', 'two']);
    expect(jsonDecode(wire.single('one').bodyText), {'name': 'alpha'});
    expect(jsonDecode(wire.single('two').bodyText), {'name': 'beta'});
    expect(wire.single('one').contentType, startsWith('application/json'));
  });

  test('serializes each nested map as one JSON part', () async {
    expect(
      await api.postDynamicMaps(
        body: {
          'counts': {'alpha': 2, 'beta': 3},
          'empty': {},
        },
      ),
      isTonikSuccess,
    );
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((p) => p.name), ['counts', 'empty']);
    expect(jsonDecode(wire.single('counts').bodyText), {'alpha': 2, 'beta': 3});
    expect(wire.single('counts').contentType, startsWith('application/json'));
    expect(wire.single('empty').bodyText, '{}');
  });

  test(
    'repeats object array names without collecting objects into one part',
    () async {
      expect(
        await api.postDynamicObjectArrays(
          body: {
            'items': [
              const ObjectArrayItem(name: 'alpha'),
              const ObjectArrayItem(name: 'beta'),
            ],
            'later': [const ObjectArrayItem(name: 'gamma')],
          },
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), ['items', 'items', 'later']);
      expect(jsonDecode(wire.parts[0].bodyText), {'name': 'alpha'});
      expect(jsonDecode(wire.parts[1].bodyText), {'name': 'beta'});
      expect(jsonDecode(wire.parts[2].bodyText), {'name': 'gamma'});
      expect(wire.parts[1].contentType, startsWith('application/json'));
    },
  );

  test(
    'keeps named JSON before dynamic primitive arrays on the wire',
    () async {
      expect(
        await api.postDynamicMixed(
          body: const DynamicMixed(
            metadata: ObjectArrayItem(name: 'meta'),
            additionalProperties: {
              'numbers': [3, 1],
              'later': [2],
              'empty': [],
            },
          ),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), [
        'metadata',
        'numbers',
        'numbers',
        'later',
      ]);
      expect(jsonDecode(wire.parts[0].bodyText), {'name': 'meta'});
      expect(wire.parts.map((p) => p.bodyText).skip(1), ['3', '1', '2']);
      expect(wire.parts[0].contentType, startsWith('application/json'));
      expect(wire.parts[1].contentType, startsWith('text/plain'));
    },
  );

  test('retains named metadata headers on a mixed root', () async {
    expect(
      await api.postDynamicMixedHeaders(
        metadataSource: 'test',
        body: const DynamicMixed(
          metadata: ObjectArrayItem(name: 'meta'),
          additionalProperties: {
            'values': [7],
          },
        ),
      ),
      isTonikSuccess,
    );
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((p) => p.name), ['metadata', 'values']);
    expect(wire.parts[0].header('x-source'), 'test');
    expect(
      wire.parts[0].contentType,
      startsWith('application/vnd.metadata+json'),
    );
    expect(wire.parts[1].header('x-source'), isNull);
    expect(wire.parts[1].bodyText, '7');
  });

  test('retains mixed constructor defaults equality and typed copyWith', () {
    const original = DynamicMixed(metadata: ObjectArrayItem(name: 'meta'));
    expect(original.additionalProperties, isEmpty);
    // The function type checks the public copyWith API at compile time.
    // ignore: omit_local_variable_types
    final DynamicMixed Function({
      ObjectArrayItem? metadata,
      Map<String, List<int>>? additionalProperties,
    })
    copy = original.copyWith;
    final changed = copy(
      additionalProperties: {
        'values': [3, 1],
      },
    );
    expect(
      changed,
      const DynamicMixed(
        metadata: ObjectArrayItem(name: 'meta'),
        additionalProperties: {
          'values': [3, 1],
        },
      ),
    );
    expect(changed.toJson(), {
      'metadata': {'name': 'meta'},
      'values': [3, 1],
    });
    expect(original.additionalProperties, isEmpty);
  });

  test(
    'sends named metadata when the additional-property map is empty',
    () async {
      expect(
        await api.postDynamicMixed(
          body: const DynamicMixed(metadata: ObjectArrayItem(name: 'meta')),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), ['metadata']);
      expect(jsonDecode(wire.parts.single.bodyText), {'name': 'meta'});
    },
  );

  test(
    'uses runtime binary names for byte and path filename fallbacks',
    () async {
      final directory = await Directory.systemTemp.createTemp('dynamic-files-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/source.bin');
      await file.writeAsBytes([4, 5]);
      expect(
        await api.postDynamicBinary(
          body: {
            'raw': TonikFileBytes(Uint8List.fromList([0, 255, 128])),
            'custom': TonikFileBytes(
              Uint8List.fromList([3]),
              fileName: r'folder\a"b.bin',
            ),
            r'path\"name': TonikFilePath(file.path),
            'empty': TonikFileBytes(Uint8List(0)),
          },
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), [
        'raw',
        'custom',
        r'path\\%22name',
        'empty',
      ]);
      expect(wire.single('raw').bodyBytes, [0, 255, 128]);
      expect(wire.single('raw').filename, 'raw');
      expect(wire.single('custom').filename, r'folder\\a%22b.bin');
      expect(wire.single(r'path\\%22name').filename, r'path\\%22name');
      expect(wire.single(r'path\\%22name').bodyBytes, [4, 5]);
      expect(wire.single('empty').bodyBytes, isEmpty);
      expect(wire.single('empty').contentType, 'application/octet-stream');
    },
  );

  test(
    'sends base64 values with runtime filenames and transfer headers',
    () async {
      expect(
        await api.postDynamicBase64(
          body: {
            r'base\name': TonikFileBytes(Uint8List.fromList([0, 255, 128, 65])),
            'custom': TonikFileBytes(
              Uint8List.fromList([1]),
              fileName: r'a\b"c.bin',
            ),
          },
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), [r'base\\name', 'custom']);
      expect(wire.parts[0].bodyText, 'AP+AQQ==');
      expect(wire.parts[0].filename, r'base\\name');
      expect(wire.parts[0].header('content-transfer-encoding'), 'base64');
      expect(wire.parts[0].contentType, 'application/octet-stream');
      expect(wire.parts[1].filename, r'a\\b%22c.bin');
    },
  );

  test(
    'repeats base64 array names and preserves headers inside both loops',
    () async {
      expect(
        await api.postDynamicBase64Arrays(
          body: {
            'files': [
              TonikFileBytes(Uint8List.fromList([0, 255])),
              TonikFileBytes(Uint8List.fromList([1]), fileName: 'one.bin'),
            ],
            'later': [
              TonikFileBytes(Uint8List.fromList([2])),
            ],
          },
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), ['files', 'files', 'later']);
      expect(wire.parts.map((p) => p.bodyText), ['AP8=', 'AQ==', 'Ag==']);
      expect(wire.parts.map((p) => p.filename), ['files', 'one.bin', 'later']);
      expect(wire.parts.map((p) => p.header('content-transfer-encoding')), [
        'base64',
        'base64',
        'base64',
      ]);
      expect(wire.parts[1].contentType, 'application/octet-stream');
    },
  );

  test(
    'uses the ordinary map API inside a multi-content multipart variant',
    () async {
      expect(
        await api.postDynamicMultiContent(
          body: const MultipartDynamicMultiContentPostBodyRequestBodyFormData({
            'a': 'alpha',
          }),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.single.name, 'a');
      expect(wire.parts.single.bodyText, 'alpha');
    },
  );

  test('keeps the shared map JSON variant unchanged', () async {
    expect(
      await api.postDynamicMultiContent(
        body: const MultipartDynamicMultiContentPostBodyRequestBodyJson({
          'a': 'alpha',
        }),
      ),
      isTonikSuccess,
    );
    final request = await server.takeRequest();
    expect(request.header('content-type'), startsWith('application/json'));
    expect(jsonDecode(request.bodyText), {'a': 'alpha'});
  });

  test(
    'rejects a collision with a present declared raw name before sending',
    () async {
      final error = requireError(
        await api.postDynamicCollision(
          body: const DynamicCollision(
            rawName: 'named',
            additionalProperties2: {'raw-name': 'extra'},
          ),
        ),
      );
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(server.requestCount, 0);
    },
  );

  test(
    'rejects a collision with an absent raw name before omitting null',
    () async {
      final error = requireError(
        await api.postDynamicCollision(
          body: const DynamicCollision(
            additionalProperties2: {'raw-name': null},
          ),
        ),
      );
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(server.requestCount, 0);
    },
  );

  test('reserves read-only property names even when absent', () async {
    final error = requireError(
      await api.postDynamicCollision(
        body: const DynamicCollision(
          additionalProperties2: {'read-only': 'extra'},
        ),
      ),
    );
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test(
    'uses the renamed additional-property field and raw names independently',
    () async {
      expect(
        await api.postDynamicCollision(
          body: const DynamicCollision(
            additionalProperties: 'named',
            additionalProperties2: {'rawName': 'dynamic'},
          ),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), [
        'additionalProperties',
        'rawName',
      ]);
      expect(wire.parts.map((p) => p.bodyText), ['named', 'dynamic']);
    },
  );

  test('rejects an empty supplied required map before sending', () async {
    final error = requireError(await api.postDynamicStrings(body: {}));
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('rejects an empty supplied optional map before sending', () async {
    final error = requireError(await api.postOptionalDynamicStrings(body: {}));
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test(
    'omits an absent optional map body and multipart content type',
    () async {
      expect(await api.postOptionalDynamicStrings(), isTonikSuccess);
      final request = await server.takeRequest();
      expect(request.bodyBytes, isEmpty);
      expect(request.header('content-type'), isNull);
    },
  );

  test('rejects a required nullable root supplied as null', () async {
    final error = requireError(await api.postDynamicNullableRoot(body: null));
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('rejects a body reduced to zero parts by null omission', () async {
    final error = requireError(
      await api.postDynamicNullableValues(body: {'a': null}),
    );
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('rejects a body reduced to zero parts by empty arrays', () async {
    final error = requireError(await api.postDynamicArrays(body: {'a': []}));
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test(
    'rejects the exact asset-upload wildcard encoding before sending',
    () async {
      final error = requireError(
        await api.postDynamicAssetsWildcard(
          base64: true,
          body: {'*': 'AP8=', 'asset': 'AQ=='},
        ),
      );
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(server.requestCount, 0);
    },
  );

  test('rejects recursive map-array values before sending', () async {
    final error = requireError(
      await api.postDynamicRecursiveMap(
        body: {
          'branch': [<String, Object?>{}],
        },
      ),
    );
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(
      (error.error as EncodingException).message,
      'Recursive collection types are not supported for dynamic '
      'multipart values.',
    );
    expect(server.requestCount, 0);
  });

  test('rejects recursive codecs even when the root map is empty', () async {
    final error = requireError(await api.postDynamicRecursiveMap(body: {}));
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(
      (error.error as EncodingException).message,
      'Recursive collection types are not supported for dynamic '
      'multipart values.',
    );
    expect(server.requestCount, 0);
  });

  test('rejects untyped dynamic values before sending', () async {
    final error = requireError(
      await api.postDynamicUntyped(body: {'a': 'value'}),
    );
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('rejects dynamic sources nested in allOf before sending', () async {
    final error = requireError(
      await api.postDynamicAllOf(
        body: const DynamicAllOf(
          dynamicMixed: DynamicMixed(
            metadata: ObjectArrayItem(name: 'meta'),
            additionalProperties: {
              'a': [1],
            },
          ),
        ),
      ),
    );
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });
  test(
    'rejects unsupported dynamic codecs even when the map is empty',
    () async {
      final error = requireError(
        await api.postDynamicUnsupportedArray(
          body: const DynamicUnsupportedArray(label: 'named'),
        ),
      );
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(server.requestCount, 0);
    },
  );

  test('rejects unsupported dynamic codecs before null omission', () async {
    final error = requireError(
      await api.postDynamicUnsupportedArray(
        body: const DynamicUnsupportedArray(
          label: 'named',
          additionalProperties: {'skip': null},
        ),
      ),
    );
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });
  test(
    'encodes mutable nested map dates using their declared JSON codec',
    () async {
      expect(
        await api.postDynamicDates(
          body: {
            'schedule': {'start': DateTime.utc(2026, 9, 14, 1, 2, 3)},
          },
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.single.name, 'schedule');
      expect(wire.parts.single.contentType, startsWith('application/json'));
      expect(jsonDecode(wire.parts.single.bodyText), {
        'start': '2026-09-14T01:02:03.000Z',
      });
    },
  );

  test(
    'encodes each repeated mutable map through the typed JSON codec',
    () async {
      expect(
        await api.postDynamicDateMaps(
          body: {
            'dates': [
              {'start': DateTime.utc(2026, 9, 14)},
              {'end': DateTime.utc(2026, 9, 15)},
            ],
          },
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), ['dates', 'dates']);
      expect(jsonDecode(wire.parts[0].bodyText), {
        'start': '2026-09-14T00:00:00.000Z',
      });
      expect(jsonDecode(wire.parts[1].bodyText), {
        'end': '2026-09-15T00:00:00.000Z',
      });
      expect(wire.parts[1].contentType, startsWith('application/json'));
    },
  );
  test(
    'keeps reserved characters literal in default dynamic enum arrays',
    () async {
      expect(
        await api.postDynamicTopics(
          body: {
            'topics': [
              DynamicTopic.fromJson('science & tech'),
              DynamicTopic.fromJson('a+b/c'),
            ],
          },
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), ['topics', 'topics']);
      expect(wire.parts.map((part) => part.bodyText), [
        'science & tech',
        'a+b/c',
      ]);
      expect(wire.parts[0].contentType, startsWith('text/plain'));
    },
  );
}
