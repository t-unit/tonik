import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/tonik_generate.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('imports and documents OpenAPI 3.2 response metadata', () async {
    final api = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Items API', 'version': '1.0.0'},
      'paths': {
        '/items': {
          'delete': {
            'operationId': 'clearItems',
            'responses': {
              '204': {'summary': 'Items cleared'},
            },
          },
          'get': {
            'operationId': 'listItems',
            'responses': {
              'default': {'description': 'Unexpected response'},
              '4XX': {'summary': 'Client error'},
              '202': {
                r'$ref': '#/components/responses/BaseResponse',
                'summary': ' \t\r\n',
                'description': '',
              },
              '201': <String, dynamic>{},
              '200': {
                r'$ref': '#/components/responses/ItemResponse',
                'summary': 'Items found',
              },
            },
          },
        },
      },
      'components': {
        'responses': {
          'BaseResponse': {
            'summary': 'Base summary',
            'description':
                '  Returns the matching items.\nResults may be empty.',
            'content': {
              'application/json': {
                'schema': {'type': 'string'},
                'example': 'ok',
              },
            },
          },
          'ItemResponse': {
            r'$ref': '#/components/responses/BaseResponse',
            'summary': 'Intermediate summary',
          },
        },
      },
    });

    final clearItems = api.operations.singleWhere(
      (operation) => operation.operationId == 'clearItems',
    );
    final cleared =
        clearItems.responses[const ExplicitResponseStatus(statusCode: 204)]!;
    expect(cleared.summary, 'Items cleared');
    expect(cleared.description, isNull);

    final listItems = api.operations.singleWhere(
      (operation) => operation.operationId == 'listItems',
    );
    final undocumented =
        listItems.responses[const ExplicitResponseStatus(statusCode: 201)]!;
    expect(undocumented.summary, isNull);
    expect(undocumented.description, isNull);

    final baseResponse = api.responses.singleWhere(
      (response) => response.name == 'BaseResponse',
    );
    expect(baseResponse.summary, 'Base summary');
    expect(
      baseResponse.description,
      '  Returns the matching items.\nResults may be empty.',
    );

    final output = Directory.systemTemp.createTempSync();
    addTearDown(() => output.deleteSync(recursive: true));
    await const Generator().generate(
      apiDocument: const ContentTypeNormalizer().apply(api),
      outputDirectory: output.path,
      package: 'items_api',
    );

    final source = File(
      path.join(
        output.path,
        'items_api',
        'lib',
        'src',
        'api_client',
        'default_api.dart',
      ),
    ).readAsStringSync();
    expect(
      source,
      contains('''
  /// **Response 204**
  ///
  /// Items cleared
'''),
    );
    expect(
      source,
      contains('''
  /// **Response 200**
  ///
  /// Items found
  ///
  ///   Returns the matching items.
  /// Results may be empty.
  ///
  /// Response 200 (application/json):
  /// **Example**:
  /// ```
  /// ok
  /// ```
  ///
  /// Response 202 (application/json):
  /// **Example**:
  /// ```
  /// ok
  /// ```
  ///
  /// **Response 400–499**
  ///
  /// Client error
  ///
  /// **Response default**
  ///
  /// Unexpected response
'''),
    );
    expect(source, isNot(contains('**Response 201**')));
    expect(source, isNot(contains('**Response 202**')));
  });
}
