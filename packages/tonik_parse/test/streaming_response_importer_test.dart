import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test(
    'imports an inline NDJSON item independently of the document version',
    () {
      final document = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Stream', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'responses': {
            'Items': {
              'description': 'Items',
              'content': {
                'Application/X-Ndjson; charset=utf-8': {
                  'itemSchema': {
                    'type': 'object',
                    'required': ['value'],
                    'properties': {
                      'value': {'type': 'integer'},
                    },
                  },
                },
              },
            },
          },
        },
      });
      final normalized = const ContentTypeNormalizer().apply(document);
      final body = normalized.responses.single.resolved.bodies.single;
      expect(body.delivery, ResponseDelivery.ndjson);
      expect(body.contentType, ContentType.bytes);
      final model = body.model as ClassModel;
      expect(model.properties.single.name, 'value');
      expect(model.properties.single.model, isA<IntegerModel>());
      expect(model.properties.single.isRequired, isTrue);
    },
  );

  test('JSONL item schema wins over a complete schema on unknown versions', () {
    final document = Importer().import({
      'openapi': 'unknown',
      'info': {'title': 'Stream', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/jsonl': {
                'schema': {'type': 'string'},
                'itemSchema': {'type': 'integer'},
              },
            },
          },
        },
      },
    });
    final body = document.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.jsonLines);
    expect(body.model, isA<IntegerModel>());
  });

  test('malformed item schema preserves the complete schema', () {
    final document =
        Importer(contentTypes: {'application/x-ndjson': ContentType.json})
            .import({
              'openapi': '3.2.0',
              'info': {'title': 'Stream', 'version': '1'},
              'paths': <String, dynamic>{},
              'components': {
                'responses': {
                  'Items': {
                    'description': 'Items',
                    'content': {
                      'application/x-ndjson': {
                        'schema': {'type': 'string'},
                        'itemSchema': {'properties': 3},
                      },
                    },
                  },
                },
              },
            });
    final body = document.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.complete);
    expect(body.model, isA<StringModel>());
  });

  test('schema-only sequential media keeps complete byte handling', () {
    final document = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Stream', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/x-ndjson': {
                'schema': {
                  'type': 'array',
                  'items': {'type': 'integer'},
                },
              },
            },
          },
        },
      },
    });
    final normalized = const ContentTypeNormalizer().apply(document);
    final body = normalized.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.complete);
    expect(body.model, isA<BinaryModel>());
  });
  test('SSE items override complete schema on older document versions', () {
    final document = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Stream', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'responses': {
          'Events': {
            'description': 'Events',
            'content': {
              'Text/Event-Stream; charset=utf-8': {
                'schema': {'type': 'string'},
                'itemSchema': {
                  'type': 'object',
                  'required': ['data'],
                  'properties': {
                    'data': {
                      'type': 'string',
                      'contentMediaType': 'application/json',
                    },
                  },
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
    expect(body.delivery, ResponseDelivery.sse);
    final model = body.model as ClassModel;
    expect(model.properties.single.name, 'data');
    expect(model.properties.single.model, isA<StringModel>());
  });

  test('SSE accepts a reusable item media type on unknown versions', () {
    final document = Importer().import({
      'openapi': 'unknown',
      'info': {'title': 'Stream', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'mediaTypes': {
          'Events': {'itemSchema': true},
        },
        'responses': {
          'Events': {
            'description': 'Events',
            'content': {
              'text/event-stream': {r'$ref': '#/components/mediaTypes/Events'},
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
    expect(body.delivery, ResponseDelivery.sse);
    expect(body.model, isA<AnyModel>());
  });

  test('JSON sequence imports normalized media and prefers itemSchema', () {
    final document = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Stream', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'Application/Json-Seq; charset=utf-8': {
                'schema': {'type': 'string'},
                'itemSchema': {'type': 'integer'},
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
    expect(body.delivery, ResponseDelivery.jsonSequence);
    expect(body.contentType, ContentType.bytes);
    expect(body.model, isA<IntegerModel>());
  });

  test('JSON sequence resolves reusable media on an unknown version', () {
    final document = Importer().import({
      'openapi': 'unknown',
      'info': {'title': 'Stream', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'mediaTypes': {
          'Alias': {r'$ref': '#/components/mediaTypes/Items'},
          'Items': {'itemSchema': true},
        },
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/json-seq': {
                r'$ref': '#/components/mediaTypes/Alias',
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
    expect(body.delivery, ResponseDelivery.jsonSequence);
    expect(body.model, isA<AnyModel>());
  });

  test('consumed external JSON sequence item schema throws', () {
    expect(
      () => Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Stream', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'responses': {
            'Items': {
              'description': 'Items',
              'content': {
                'application/json-seq': {
                  'itemSchema': {r'$ref': 'other.yaml#/Value'},
                },
                'application/json': {
                  'schema': {'type': 'integer'},
                },
              },
            },
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test(
    'JSON sequence without a usable item schema keeps ordinary defaults',
    () {
      final document = Importer().import({
        'openapi': '3.2.0',
        'info': {'title': 'Stream', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'responses': {
            'Items': {
              'description': 'Items',
              'content': {
                'application/json-seq': {
                  'schema': {'type': 'string'},
                  'itemSchema': {'properties': 3},
                },
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
        (body) => body.rawContentType == 'application/json-seq',
      );
      final json = bodies.singleWhere(
        (body) => body.rawContentType == 'application/json',
      );
      expect(sequence.delivery, ResponseDelivery.complete);
      expect(sequence.model, isA<BinaryModel>());
      expect(json.delivery, ResponseDelivery.complete);
      expect(json.model, isA<IntegerModel>());
    },
  );

  test('SSE schema-only media preserves configured complete handling', () {
    final document =
        Importer(contentTypes: {'text/event-stream': ContentType.text}).import({
          'openapi': '3.2.0',
          'info': {'title': 'Stream', 'version': '1'},
          'paths': <String, dynamic>{},
          'components': {
            'responses': {
              'Events': {
                'description': 'Events',
                'content': {
                  'text/event-stream': {
                    'schema': {'type': 'string'},
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
    expect(body.contentType, ContentType.text);
    expect(body.model, isA<StringModel>());
  });

  test('malformed SSE item schema preserves ordinary sibling media', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Stream', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'responses': {
          'Events': {
            'description': 'Events',
            'content': {
              'text/event-stream': {
                'itemSchema': {'properties': 3},
              },
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
    final sse = bodies.singleWhere(
      (body) => body.rawContentType == 'text/event-stream',
    );
    final json = bodies.singleWhere(
      (body) => body.rawContentType == 'application/json',
    );
    expect(sse.delivery, ResponseDelivery.complete);
    expect(sse.model, isA<BinaryModel>());
    expect(json.delivery, ResponseDelivery.complete);
    expect(json.model, isA<IntegerModel>());
  });
}
