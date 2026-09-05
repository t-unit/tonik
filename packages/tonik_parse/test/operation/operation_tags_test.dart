import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'tags': [
      {'name': 'info', 'description': 'Info operations'},
      {'name': 'test', 'description': 'Test operations'},
      {'name': 'post'},
    ],
    'paths': {
      '/info': {
        'get': {
          'operationId': 'getInfo',
          'tags': ['info'],
          'responses': {
            '200': {'description': 'Successful response'},
          },
        },
        'post': {
          'operationId': 'postInfo',
          'tags': ['info', 'post'],
          'responses': {
            '201': {'description': 'Created response'},
          },
        },
      },
      '/test': {
        'get': {
          'operationId': 'getTest',
          'tags': ['test'],
          'responses': {
            '200': {'description': 'Successful response'},
          },
        },
        'trace': {
          'operationId': 'traceTest',
          'tags': ['trace'],
          'responses': {
            '200': {'description': 'Successful response'},
          },
        },
        'delete': {
          'operationId': 'deleteTest',
          'responses': {
            '200': {'description': 'Successful response'},
          },
        },
      },
    },
    'servers': <dynamic>[],
  };

  test('registers undeclared tags', () {
    final api = Importer().import(fileContent);

    final trace = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'traceTest',
    );
    expect(trace, isNotNull);
    expect(trace?.tags.single.name, 'trace');
    expect(trace?.tags.single.description, isNull);
    expect(trace?.tags.single.nameOverride, isNull);
  });

  test('handles operations without tags', () {
    final api = Importer().import(fileContent);

    final deleteTest = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'deleteTest',
    );
    expect(deleteTest, isNotNull);
    expect(deleteTest?.tags, isEmpty);
  });

  test('handles operations with multiple tags', () {
    final api = Importer().import(fileContent);

    final post = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postInfo',
    );

    expect(post, isNotNull);
    expect(post?.tags, hasLength(2));

    final postTag = post?.tags.firstWhereOrNull((t) => t.name == 'post');
    final infoTag = post?.tags.firstWhereOrNull((t) => t.name == 'info');

    expect(postTag, isNotNull);
    expect(postTag?.description, isNull);

    expect(infoTag, isNotNull);
    expect(infoTag?.description, 'Info operations');
  });

  test('does not require tags with description', () {
    final api = Importer().import(fileContent);

    final getInfo = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postInfo',
    );

    final postTag = getInfo?.tags.firstWhereOrNull((tag) => tag.name == 'post');

    expect(postTag, isNotNull);
    expect(postTag?.description, isNull);
  });

  group('operation tag registry', () {
    Map<String, dynamic> spec({List<Map<String, dynamic>>? declarations}) => {
      'openapi': '3.0.3',
      'info': {'title': 'Tags', 'version': '1.0.0'},
      'tags': ?declarations,
      'paths': {
        '/first': {
          'get': {
            'operationId': 'first',
            'tags': ['Accounts', 'Zone', 'Accounts'],
            'responses': <String, dynamic>{},
          },
        },
        '/second': {
          'get': {
            'operationId': 'second',
            'tags': ['Accounts'],
            'responses': <String, dynamic>{},
          },
        },
        '/empty': {
          'get': {
            'operationId': 'empty',
            'tags': <String>[],
            'responses': <String, dynamic>{},
          },
        },
        '/missing': {
          'get': {'operationId': 'missing', 'responses': <String, dynamic>{}},
        },
      },
    };

    for (final declarations in [null, <Map<String, dynamic>>[]]) {
      test('imports tags with top-level tags $declarations', () {
        final api = Importer().import(spec(declarations: declarations));
        final first = api.operations.first;
        final second = api.operations.elementAt(1);

        expect(first.tags.map((tag) => tag.name), ['Accounts', 'Zone']);
        expect(second.tags.single, same(first.tags.first));
        expect(api.operationsByTag, {
          first.tags.first: {first, second},
          first.tags.last: {first},
        });
        expect(api.operations.skip(2).every((op) => op.tags.isEmpty), isTrue);
        expect(api.operations, hasLength(4));
      });
    }

    test('preserves declared metadata alongside undeclared tags', () {
      final api = Importer().import(
        spec(
          declarations: [
            {
              'name': 'Accounts',
              'description': 'Manage accounts',
              'x-dart-name': 'AccountManagement',
            },
          ],
        ),
      );
      final first = api.operations.first;
      final accountTag = first.tags.first;

      expect(accountTag.name, 'Accounts');
      expect(accountTag.description, 'Manage accounts');
      expect(accountTag.nameOverride, 'AccountManagement');
      expect(api.operations.elementAt(1).tags.single, same(accountTag));
      expect(first.tags.last.name, 'Zone');
      expect(first.tags.last.description, isNull);
      expect(first.tags.last.nameOverride, isNull);
    });

    test('does not share mutable registry state across imports', () {
      final importer = Importer();
      final first = importer.import(spec());
      first.operations.first.tags.first
        ..description = 'Changed'
        ..nameOverride = 'Changed';
      final second = importer.import(spec());

      expect(
        second.operations.first.tags.first,
        isNot(same(first.operations.first.tags.first)),
      );
      expect(second.operations.first.tags.first.description, isNull);
      expect(second.operations.first.tags.first.nameOverride, isNull);
      expect(
        second.operationsByTag.keys.map((tag) => tag.name),
        first.operationsByTag.keys.map((tag) => tag.name),
      );
    });

    test('filters by newly registered tags and applies shared overrides', () {
      final api = Importer().import(spec());
      final accountTag = api.operations.first.tags.first;
      final transformed = const ConfigTransformer().apply(
        api,
        const TonikConfig(
          filter: FilterConfig(includeTags: ['Accounts']),
          nameOverrides: NameOverridesConfig(tags: {'Accounts': 'Customer'}),
        ),
      );

      expect(transformed.operations.map((op) => op.operationId), [
        'first',
        'second',
      ]);
      expect(transformed.operationsByTag[accountTag], hasLength(2));
      expect(accountTag.name, 'Accounts');
      expect(accountTag.nameOverride, 'Customer');
      expect(transformed.operations.last.tags.single, same(accountTag));
      expect(transformed.operations.first.tags.last.name, 'Zone');
    });

    test('excludes operations by newly registered tag', () {
      final transformed = const ConfigTransformer().apply(
        Importer().import(spec()),
        const TonikConfig(filter: FilterConfig(excludeTags: ['Zone'])),
      );
      expect(transformed.operations.map((op) => op.operationId), [
        'second',
        'empty',
        'missing',
      ]);
    });

    test('preserves exact names before naming normalization', () {
      final content = spec();
      content['paths'] = {
        '/names': {
          'get': {
            'tags': ['zone', 'Zone', ' Zone ', 'zone-name', 'zone_name'],
            'responses': <String, dynamic>{},
          },
        },
      };
      final api = Importer().import(content);
      expect(api.operations.single.tags.map((tag) => tag.name), [
        'zone',
        'Zone',
        ' Zone ',
        'zone-name',
        'zone_name',
      ]);
      expect(api.operationsByTag, hasLength(5));
    });
  });
}
