import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('malformed optional media fields preserve a usable item schema', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/x-ndjson': {
                'schema': {'properties': 3},
                'itemSchema': {'type': 'integer'},
                'encoding': 3,
                'examples': ['invalid'],
              },
              'application/json': {
                'schema': {'type': 'string'},
                'itemSchema': null,
              },
            },
          },
        },
      },
    });
    final bodies = document.responses.single.resolved.bodies.toList();
    expect(bodies[0].delivery, ResponseDelivery.ndjson);
    expect(bodies[0].model, isA<IntegerModel>());
    expect(bodies[1].delivery, ResponseDelivery.complete);
    expect(bodies[1].model, isA<StringModel>());
  });

  test('malformed optional map entries preserve usable sibling entries', () {
    final media = MediaType.fromJson({
      'itemSchema': {'type': 'integer'},
      'encoding': {
        'invalid': {'style': 'unknown'},
        'wrongType': 3,
        'valid': {'contentType': 'application/json'},
      },
      'examples': {
        'invalid': {'summary': 3},
        'wrongType': null,
        'valid': {'value': 7},
      },
    });
    expect(media.itemSchema!.type, ['integer']);
    expect(media.encoding!.keys, ['valid']);
    expect(media.encoding!['valid']!.contentType, 'application/json');
    expect(media.examples!.keys, ['valid']);
  });

  test('null item schemas retain complete schema handling', () {
    final document =
        Importer(contentTypes: {'application/x-ndjson': ContentType.json})
            .import({
              'openapi': '3.2.0',
              'info': {'title': 'Media', 'version': '1'},
              'paths': <String, dynamic>{},
              'components': {
                'responses': {
                  'Items': {
                    'description': 'Items',
                    'content': {
                      'application/x-ndjson': {
                        'schema': {'type': 'integer'},
                        'itemSchema': null,
                      },
                    },
                  },
                },
              },
            });
    final body = document.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.complete);
    expect(body.model, isA<IntegerModel>());
  });

  test(
    'unsupported framing retains complete schema without consuming items',
    () {
      final document = Importer().import({
        'openapi': '3.2.0',
        'info': {'title': 'Media', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'responses': {
            'Items': {
              'description': 'Items',
              'content': {
                'text/plain': {
                  'schema': {'type': 'string'},
                  'itemSchema': {r'$ref': '#/components/schemas/Unconsumed'},
                },
              },
            },
          },
        },
      });
      final body = document.responses.single.resolved.bodies.single;
      expect(body.delivery, ResponseDelivery.complete);
      expect(body.model, isA<StringModel>());
    },
  );
}
