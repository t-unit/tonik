import 'package:collection/collection.dart';
import 'package:test/test.dart';
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
        'description': 'Post operations',
      },
      {
        'name': 'unused',
      }
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

  test('sorts operations into tags', () {
    final api = Importer().import(fileContent);

    // Info
    final info = api.taggedOperations.firstWhereOrNull(
      (to) => to.tagName == 'info',
    );

    expect(info, isNotNull);
    expect(info?.tagDescription, 'Info operations');
    expect(info?.operations, hasLength(2));

    final getInfo = info?.operations.firstWhereOrNull(
      (o) => o.operationId == 'getInfo',
    );
    expect(getInfo, isNotNull);

    final postInfo = info?.operations.firstWhereOrNull(
      (o) => o.operationId == 'postInfo',
    );
    expect(postInfo, isNotNull);

    // Test
    final test = api.taggedOperations.firstWhereOrNull(
      (to) => to.tagName == 'test',
    );

    expect(test, isNotNull);
    expect(test?.tagDescription, 'Test operations');
    expect(test?.operations, hasLength(1));

    final getTest = test?.operations.firstWhereOrNull(
      (o) => o.operationId == 'getTest',
    );
    expect(getTest, isNotNull);
  });

  test('duplicates operations with multiple tags', () {
    final api = Importer().import(fileContent);

    final post = api.taggedOperations.firstWhereOrNull(
      (to) => to.tagName == 'post',
    );
    final postInfo1 = post?.operations.firstWhereOrNull(
      (o) => o.operationId == 'postInfo',
    );
    expect(postInfo1, isNotNull);

    final info = api.taggedOperations.firstWhereOrNull(
      (to) => to.tagName == 'info',
    );

    final postInfo2 = info?.operations.firstWhereOrNull(
      (o) => o.operationId == 'postInfo',
    );
    expect(postInfo2, isNotNull);
  });

  test('ignores unknown tags', () {
    final api = Importer().import(fileContent);

    final trace = api.taggedOperations.firstWhereOrNull(
      (to) => to.tagName == 'trace',
    );
    expect(trace, isNull);

    final noTag = api.taggedOperations.firstWhereOrNull(
      (to) => to.tagName == null,
    );
    final traceTest = noTag?.operations.firstWhereOrNull(
      (o) => o.operationId == 'traceTest',
    );
    expect(traceTest, isNotNull);
  });

  test('handles operations without tags', () {
    final api = Importer().import(fileContent);

    final noTag = api.taggedOperations.firstWhereOrNull(
      (to) => to.tagName == null,
    );
    final deleteTest = noTag?.operations.firstWhereOrNull(
      (o) => o.operationId == 'deleteTest',
    );
    expect(deleteTest, isNotNull);
  });

  test('ignores unused tags', () {
    final api = Importer().import(fileContent);

    final unused = api.taggedOperations.firstWhereOrNull(
      (to) => to.tagName == 'unused',
    );
    expect(unused, isNull);
  });
}
