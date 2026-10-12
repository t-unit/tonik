import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test(
    'custom mappings import each streaming format and preserve media names',
    () {
      final document =
          Importer(
            contentTypes: {
              'application/vnd.example.ndjson': StreamingContentType.ndjson,
              'application/vnd.example.lines; profile=records':
                  StreamingContentType.jsonLines,
              'application/geo+json-seq': StreamingContentType.jsonSequence,
              'application/vnd.example.events': StreamingContentType.sse,
            },
          ).import({
            'openapi': 'unknown',
            'info': {'title': 'Stream', 'version': '1'},
            'paths': <String, dynamic>{},
            'components': {
              'mediaTypes': {
                'Items': {
                  'itemSchema': {'type': 'integer'},
                },
              },
              'responses': {
                'Items': {
                  'description': 'Items',
                  'content': {
                    'Application/Vnd.Example.Ndjson; charset=utf-8': {
                      r'$ref': '#/components/mediaTypes/Items',
                    },
                    'application/vnd.example.lines; profile=records': {
                      'itemSchema': {'type': 'string'},
                    },
                    'application/geo+json-seq': {
                      'schema': {'type': 'string'},
                      'itemSchema': {'type': 'boolean'},
                    },
                    'application/vnd.example.events': {
                      'itemSchema': {
                        'type': 'object',
                        'required': ['data'],
                        'properties': {
                          'data': {'type': 'string'},
                        },
                      },
                    },
                  },
                },
              },
            },
          });

      final bodies = const ContentTypeNormalizer()
          .apply(document)
          .responses
          .single
          .resolved
          .bodies;
      final ndjson = bodies.singleWhere(
        (body) => body.delivery == ResponseDelivery.ndjson,
      );
      final jsonLines = bodies.singleWhere(
        (body) => body.delivery == ResponseDelivery.jsonLines,
      );
      final jsonSequence = bodies.singleWhere(
        (body) => body.delivery == ResponseDelivery.jsonSequence,
      );
      final sse = bodies.singleWhere(
        (body) => body.delivery == ResponseDelivery.sse,
      );

      expect(bodies, hasLength(4));
      expect(
        ndjson.rawContentType,
        'Application/Vnd.Example.Ndjson; charset=utf-8',
      );
      expect(ndjson.contentType, ContentType.bytes);
      expect(ndjson.model, isA<IntegerModel>());
      expect(
        jsonLines.rawContentType,
        'application/vnd.example.lines; profile=records',
      );
      expect(jsonLines.model, isA<StringModel>());
      expect(jsonSequence.rawContentType, 'application/geo+json-seq');
      expect(jsonSequence.model, isA<BooleanModel>());
      expect(sse.rawContentType, 'application/vnd.example.events');
      final event = sse.model as ClassModel;
      expect(event.properties.single.name, 'data');
      expect(event.properties.single.model, isA<StringModel>());
    },
  );

  test('explicit streaming mapping overrides the standard delivery format', () {
    final document =
        Importer(
          contentTypes: {
            'application/x-ndjson': StreamingContentType.jsonSequence,
          },
        ).import({
          'openapi': '3.0.3',
          'info': {'title': 'Stream', 'version': '1'},
          'paths': <String, dynamic>{},
          'components': {
            'responses': {
              'Items': {
                'description': 'Items',
                'content': {
                  'application/x-ndjson': {
                    'schema': {'type': 'string'},
                    'itemSchema': {'type': 'integer'},
                  },
                },
              },
            },
          },
        });

    final body = document.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.jsonSequence);
    expect(body.model, isA<IntegerModel>());
  });

  test(
    'ordinary mapping overrides streaming without resolving the item schema',
    () {
      final document =
          Importer(contentTypes: {'application/jsonl': ContentType.json})
              .import({
                'openapi': '3.2.0',
                'info': {'title': 'Stream', 'version': '1'},
                'paths': <String, dynamic>{},
                'components': {
                  'responses': {
                    'Items': {
                      'description': 'Items',
                      'content': {
                        'application/jsonl': {
                          'schema': {'type': 'integer'},
                          'itemSchema': {
                            r'$ref': '#/components/schemas/Unconsumed',
                          },
                        },
                      },
                    },
                  },
                },
              });

      final body = const ContentTypeNormalizer()
          .apply(document)
          .responses
          .single
          .resolved
          .bodies
          .single;
      expect(body.delivery, ResponseDelivery.complete);
      expect(body.contentType, ContentType.json);
      expect(body.model, isA<IntegerModel>());
    },
  );

  test(
    'configured streaming without usable items preserves ordinary alternatives',
    () {
      final document =
          Importer(
            contentTypes: {
              'application/geo+json-seq': StreamingContentType.jsonSequence,
              'application/vnd.example.lines': StreamingContentType.jsonLines,
            },
          ).import({
            'openapi': '3.1.0',
            'info': {'title': 'Stream', 'version': '1'},
            'paths': <String, dynamic>{},
            'components': {
              'responses': {
                'Items': {
                  'description': 'Items',
                  'content': {
                    'application/geo+json-seq': {
                      'schema': {'type': 'string'},
                      'itemSchema': {'properties': 3},
                    },
                    'application/vnd.example.lines': <String, dynamic>{},
                    'application/json': {
                      'schema': {'type': 'integer'},
                    },
                  },
                },
              },
            },
          });

      final bodies = const ContentTypeNormalizer()
          .apply(document)
          .responses
          .single
          .resolved
          .bodies;
      final sequence = bodies.singleWhere(
        (body) => body.rawContentType == 'application/geo+json-seq',
      );
      final lines = bodies.singleWhere(
        (body) => body.rawContentType == 'application/vnd.example.lines',
      );
      final json = bodies.singleWhere(
        (body) => body.rawContentType == 'application/json',
      );
      expect(sequence.delivery, ResponseDelivery.complete);
      expect(sequence.contentType, ContentType.bytes);
      expect(sequence.model, isA<BinaryModel>());
      expect(lines.delivery, ResponseDelivery.complete);
      expect(lines.model, isA<BinaryModel>());
      expect(json.delivery, ResponseDelivery.complete);
      expect(json.model, isA<IntegerModel>());
    },
  );

  test(
    'configured streaming requests remain complete bytes and ignore itemSchema',
    () {
      final document =
          Importer(
            contentTypes: {
              'application/vnd.example.events': StreamingContentType.sse,
            },
          ).import({
            'openapi': '3.2.0',
            'info': {'title': 'Stream', 'version': '1'},
            'paths': <String, dynamic>{},
            'components': {
              'requestBodies': {
                'Events': {
                  'content': {
                    'application/vnd.example.events': {
                      'schema': {'type': 'string'},
                      'itemSchema': {r'$ref': 'other.yaml#/Unconsumed'},
                    },
                  },
                },
              },
            },
          });

      final body =
          const ContentTypeNormalizer().apply(document).requestBodies.single
              as RequestBodyObject;
      final content = body.content.single as ModelRequestContent;
      expect(content.rawContentType, 'application/vnd.example.events');
      expect(content.contentType, ContentType.bytes);
      expect(content.model, isA<BinaryModel>());
    },
  );

  test(
    'configured streaming still throws for a missing consumed item reference',
    () {
      expect(
        () =>
            Importer(
              contentTypes: {
                'application/geo+json-seq': StreamingContentType.jsonSequence,
              },
            ).import({
              'openapi': '3.0.3',
              'info': {'title': 'Stream', 'version': '1'},
              'paths': <String, dynamic>{},
              'components': {
                'responses': {
                  'Items': {
                    'description': 'Items',
                    'content': {
                      'application/geo+json-seq': {
                        'itemSchema': {r'$ref': '#/components/schemas/Missing'},
                      },
                    },
                  },
                },
              },
            }),
        throwsArgumentError,
      );
    },
  );
}
