import 'dart:convert';

import 'package:recursive_map_api/recursive_map_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  RecursiveApi buildApi() => RecursiveApi(
    CustomServer(baseUrl: baseUrl),
  );

  Object? decodeEchoBody(Object? echoHeader) {
    if (echoHeader is List) {
      final value = echoHeader.first;
      if (value is String) {
        return jsonDecode(utf8.decode(base64Decode(value)));
      }
    }
    if (echoHeader is String) {
      return jsonDecode(utf8.decode(base64Decode(echoHeader)));
    }
    throw StateError('Missing X-Echo-Body header in response');
  }

  group('Tree (direct self-referential map)', () {
    test('getTree decodes nested JSON through _decodeTree', () async {
      final api = buildApi();
      final result = await api.getTree();
      expect(result, isA<TonikSuccess<Tree>>());
      final tree = (result as TonikSuccess<Tree>).value;

      final a = tree['a']! as Tree;
      final b = a['b']! as Tree;
      final c = b['c']! as Tree;
      expect(c, isEmpty);
      final d = tree['d']! as Tree;
      expect(d, isEmpty);
    });

    test(
      'postTree round-trips through _encodeTree and matches the source map',
      () async {
        final original = <String, Object?>{
          'a': <String, Object?>{
            'b': <String, Object?>{'c': <String, Object?>{}},
          },
          'd': <String, Object?>{},
        };

        final api = buildApi();
        final result = await api.postTree(body: original);
        expect(result, isA<TonikSuccess<void>>());

        final response = (result as TonikSuccess<void>).response;
        final echoed = decodeEchoBody(response.headers.map['x-echo-body']);
        expect(_isDeepEqual(echoed, original), isTrue);
      },
    );
  });

  group('Forest (direct self-referential list)', () {
    test(
      'getForest decodes nested JSON arrays through _decodeForest',
      () async {
        final api = buildApi();
        final result = await api.getForest();
        expect(result, isA<TonikSuccess<Forest>>());
        final forest = (result as TonikSuccess<Forest>).value;

        expect(forest, hasLength(2));
        final outer0 = forest[0]! as Forest;
        expect(outer0, hasLength(1));
        final inner = outer0[0]! as Forest;
        expect(inner, isEmpty);
        final outer1 = forest[1]! as Forest;
        expect(outer1, isEmpty);
      },
    );

    test(
      'postForest round-trips through _encodeForest and matches the source',
      () async {
        final original = <Object?>[
          <Object?>[<Object?>[]],
          <Object?>[],
        ];

        final api = buildApi();
        final result = await api.postForest(body: original);
        expect(result, isA<TonikSuccess<void>>());

        final response = (result as TonikSuccess<void>).response;
        final echoed = decodeEchoBody(response.headers.map['x-echo-body']);
        expect(_isDeepEqual(echoed, original), isTrue);
      },
    );
  });

  group('Node (class wrapping a recursive Tree property)', () {
    test('getNode decodes a Node containing a nested Tree subtree', () async {
      final api = buildApi();
      final result = await api.getNode();
      expect(result, isA<TonikSuccess<Node>>());
      final node = (result as TonikSuccess<Node>).value;

      expect(node.id, 'root');
      final left = node.subtree['left']! as Tree;
      expect(left, isA<Tree>());
      final leaf = left['leaf']! as Tree;
      expect(leaf, isEmpty);
      final right = node.subtree['right']! as Tree;
      expect(right, isEmpty);
    });

    test(
      'Node round-trips through the generated toJson/fromJson and POST helper',
      () async {
        const original = Node(
          id: 'root',
          subtree: <String, Object?>{
            'a': <String, Object?>{
              'aa': <String, Object?>{},
              'ab': <String, Object?>{},
            },
            'b': <String, Object?>{},
          },
        );

        final encodedJson = original.toJson()! as Map<String, Object?>;
        final decoded = Node.fromJson(encodedJson);
        expect(decoded.id, original.id);
        expect(_isDeepEqual(decoded.subtree, original.subtree), isTrue);

        final api = buildApi();
        final result = await api.postNode(body: original);
        expect(result, isA<TonikSuccess<void>>());

        final response = (result as TonikSuccess<void>).response;
        final echoed = decodeEchoBody(response.headers.map['x-echo-body']);
        expect(_isDeepEqual(echoed, encodedJson), isTrue);
      },
    );
  });

  group('AMap / BMap (indirect cycle)', () {
    test('getAMap decodes an AMap containing a BMap leaf', () async {
      final api = buildApi();
      final result = await api.getAMap();
      expect(result, isA<TonikSuccess<AMap>>());
      final root = (result as TonikSuccess<AMap>).value;

      final b = root['b']! as BMap;
      final a = b['a']! as AMap;
      expect(a, isEmpty);
    });

    test('AMap round-trips through the POST helper', () async {
      final original = <String, Object?>{
        'b': <String, Object?>{
          'a': <String, Object?>{
            'b': <String, Object?>{},
          },
        },
      };

      final api = buildApi();
      final result = await api.postAMap(body: original);
      expect(result, isA<TonikSuccess<void>>());

      final response = (result as TonikSuccess<void>).response;
      final echoed = decodeEchoBody(response.headers.map['x-echo-body']);
      expect(_isDeepEqual(echoed, original), isTrue);
    });
  });
}

bool _isDeepEqual(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (!_isDeepEqual(entry.value, b[entry.key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_isDeepEqual(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
