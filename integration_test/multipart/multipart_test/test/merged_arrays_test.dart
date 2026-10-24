import 'dart:convert';

import 'package:multipart_3_1_api/multipart_3_1_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test(
    'sends equal array properties once and retains duplicate items',
    () async {
      final server = await RawRequestServer.start();
      final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));
      const body = MergedArrays(
        mergedArraysBase: MergedArraysBase(tags: ['a', 'a', 'b']),
        mergedArraysExtension: MergedArraysExtension(tags: ['a', 'a', 'b']),
      );

      expect(await api.postMergedArrays(body: body), isTonikSuccess);

      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), ['tags', 'tags', 'tags']);
      expect(wire.parts.map((part) => part.bodyText), ['a', 'a', 'b']);
      expect(body.toJson(), {
        'tags': ['a', 'a', 'b'],
      });
    },
  );

  test('rejects reordered array properties before sending', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    final error = requireError(
      await api.postMergedArrays(
        body: const MergedArrays(
          mergedArraysBase: MergedArraysBase(tags: ['a', 'b']),
          mergedArraysExtension: MergedArraysExtension(tags: ['b', 'a']),
        ),
      ),
    );

    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('uses an array supplied by only one member', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    expect(
      await api.postMergedArrays(
        body: const MergedArrays(
          mergedArraysBase: MergedArraysBase(),
          mergedArraysExtension: MergedArraysExtension(tags: ['a', 'a']),
        ),
      ),
      isTonikSuccess,
    );

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['tags', 'tags']);
    expect(wire.parts.map((part) => part.bodyText), ['a', 'a']);
  });

  test('equal empty arrays keep the existing omitted-part behavior', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    expect(
      await api.postMergedArrays(
        body: const MergedArrays(
          mergedArraysBase: MergedArraysBase(label: 'kept', tags: []),
          mergedArraysExtension: MergedArraysExtension(tags: []),
        ),
      ),
      isTonikSuccess,
    );

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['label']);
    expect(wire.single('label').bodyText, 'kept');
  });

  test('reconciles style-object, dynamic, and nested map arrays', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));
    // Allocate each nested collection separately to verify deep equality.
    final firstRawValue = [
      [1, 1],
      [2],
      {'label': 'same'},
    ];
    final secondRawValue = [
      [1, 1],
      [2],
      {'label': 'same'},
    ];
    final firstMetadata = {
      'nested': {
        'values': [
          [1, 1],
          [2],
        ],
      },
      'first': 'left',
    };
    final secondMetadata = {
      'nested': {
        'values': [
          [1, 1],
          [2],
        ],
      },
      'second': 'right',
    };

    expect(
      await api.postMergedArrays(
        body: MergedArrays(
          mergedArraysBase: MergedArraysBase(
            attributes: const MergedArrayAttributes(labels: ['a', 'a', 'b']),
            rawValue: firstRawValue,
            metadata: firstMetadata,
          ),
          mergedArraysExtension: MergedArraysExtension(
            attributes: const MergedArrayAttributes(labels: ['a', 'a', 'b']),
            rawValue: secondRawValue,
            metadata: secondMetadata,
          ),
        ),
      ),
      isTonikSuccess,
    );

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.single('labels').bodyText, 'a,a,b');
    expect(jsonDecode(wire.single('rawValue').bodyText), [
      [1, 1],
      [2],
      {'label': 'same'},
    ]);
    expect(jsonDecode(wire.single('metadata').bodyText), {
      'nested': {
        'values': [
          [1, 1],
          [2],
        ],
      },
      'first': 'left',
      'second': 'right',
    });
  });

  test('rejects conflicting style-object array properties', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    final error = requireError(
      await api.postMergedArrays(
        body: const MergedArrays(
          mergedArraysBase: MergedArraysBase(
            attributes: MergedArrayAttributes(labels: ['a']),
          ),
          mergedArraysExtension: MergedArraysExtension(
            attributes: MergedArrayAttributes(labels: ['b']),
          ),
        ),
      ),
    );

    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('rejects conflicting dynamic array values', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    final error = requireError(
      await api.postMergedArrays(
        body: const MergedArrays(
          mergedArraysBase: MergedArraysBase(
            rawValue: [
              [1],
              [2],
            ],
          ),
          mergedArraysExtension: MergedArraysExtension(
            rawValue: [
              [1],
              [3],
            ],
          ),
        ),
      ),
    );

    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('rejects conflicting arrays nested in merged maps', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    final error = requireError(
      await api.postMergedArrays(
        body: const MergedArrays(
          mergedArraysBase: MergedArraysBase(
            metadata: {
              'nested': {
                'values': [1, 1],
              },
            },
          ),
          mergedArraysExtension: MergedArraysExtension(
            metadata: {
              'nested': {
                'values': [1],
              },
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
    'compares iterable contents even when their equality returns true',
    () async {
      final server = await RawRequestServer.start();
      final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

      final error = requireError(
        await api.postMergedArrays(
          body: const MergedArrays(
            mergedArraysBase: MergedArraysBase(
              metadata: {'values': _EqualIterable(1)},
            ),
            mergedArraysExtension: MergedArraysExtension(
              metadata: {'values': _EqualIterable(2)},
            ),
          ),
        ),
      );

      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(server.requestCount, 0);
    },
  );
}

class const _EqualIterable(final int value)
    extends Iterable<int>
    implements JsonEncodable {
  @override
  Iterator<int> get iterator => [value].iterator;

  @override
  List<int> toJson() => [value];

  @override
  // Deliberately misleading equality exercises content-based reconciliation.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => other is _EqualIterable;

  @override
  // Match the deliberately misleading equality used by this test helper.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => 0;
}
