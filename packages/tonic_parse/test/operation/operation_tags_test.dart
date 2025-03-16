import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
    },
    'tags': [
      {
        'name': 'info',
        'description': 'Info operations',
      },
      {
        'name': 'test',
        'description': 'Test operations',
      },
      {
        'name': 'post',
      },
    ],
    'paths': {
      '/info': {
        'get': {
          'operationId': 'getInfo',
          'tags': ['info'],
          'responses': {
            '200': {
              'description': 'Successful response',
            },
          },
        },
        'post': {
          'operationId': 'postInfo',
          'tags': ['info', 'post'],
          'responses': {
            '201': {
              'description': 'Created response',
            },
          },
        },
      },
      '/test': {
        'get': {
          'operationId': 'getTest',
          'tags': ['test'],
          'responses': {
            '200': {
              'description': 'Successful response',
            },
          },
        },
        'trace': {
          'operationId': 'traceTest',
          'tags': ['trace'],
          'responses': {
            '200': {
              'description': 'Successful response',
            },
          },
        },
        'delete': {
          'operationId': 'deleteTest',
          'responses': {
            '200': {
              'description': 'Successful response',
            },
          },
        },
      },
    },
    'servers': <dynamic>[],
  };

  test('ignores unknown tags', () {
    final api = Importer().import(fileContent);

    final trace = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'traceTest',
    );
    expect(trace, isNotNull);
    expect(trace?.tags, isEmpty);
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

    expect(
      post?.tags,
      containsAll(
        [
          const Tag(name: 'post'),
          const Tag(name: 'info', description: 'Info operations'),
        ],
      ),
    );
  });

  test('does not require tags with description', () {
    final api = Importer().import(fileContent);

    final getInfo = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postInfo',
    );

    final postTag = getInfo?.tags.firstWhereOrNull(
      (tag) => tag.name == 'post',
    );

    expect(postTag, isNotNull);
    expect(postTag?.description, isNull);
  });
}
