import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model_importer.dart';
import 'package:tonik_parse/src/request_body_importer.dart';
import 'package:tonik_parse/src/response_header_importer.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test(
    '3.0.3 missing schema multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {'multipart/form-data': <String, dynamic>{}},
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.0.3 string multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {'type': 'string'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.0.3 integer multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {'type': 'integer'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.0.3 boolean multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {'type': 'boolean'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.0.3 boolean schema multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {'schema': true},
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.0.3 false schema multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {'schema': false},
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test('3.0.3 null multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {'type': 'null'},
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test(
    '3.0.3 multiple types multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {
                    'type': ['string', 'object'],
                  },
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test('3.0.3 map multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'type': 'object',
                  'additionalProperties': {'type': 'string'},
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test(
    '3.0.3 referenced binary multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Binary': {'type': 'string', 'format': 'binary'},
            'BinaryAlias': {r'$ref': '#/components/schemas/Binary'},
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Binary'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.0.3 aliased binary multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Binary': {'type': 'string', 'format': 'binary'},
            'BinaryAlias': {r'$ref': '#/components/schemas/Binary'},
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/BinaryAlias'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.0.3 referenced map multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Map': {
              'type': 'object',
              'additionalProperties': {'type': 'string'},
            },
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Map'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.0.3 referenced composition multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Composed': {
              'allOf': [
                {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
                {
                  'type': 'object',
                  'properties': {
                    'count': {'type': 'integer'},
                  },
                },
              ],
            },
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Composed'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.0.3 annotated composition multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Composed': {
              'allOf': [
                {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
                {
                  'type': 'object',
                  'properties': {
                    'count': {'type': 'integer'},
                  },
                },
              ],
            },
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {
                    r'$ref': '#/components/schemas/Composed',
                    'description': 'Upload',
                    'nullable': true,
                  },
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test('3.0.3 allOf multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'allOf': [
                    {'type': 'string'},
                  ],
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test('3.0.3 oneOf multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'oneOf': [
                    {'type': 'string'},
                    {'type': 'object'},
                  ],
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test('3.0.3 anyOf multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'anyOf': [
                    {'type': 'string'},
                    {'type': 'object'},
                  ],
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test('3.0.3 array multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test(
    '3.1.0 missing schema multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {'multipart/form-data': <String, dynamic>{}},
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.1.0 string multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {'type': 'string'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.1.0 integer multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {'type': 'integer'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.1.0 boolean multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {'type': 'boolean'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.1.0 boolean schema multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {'schema': true},
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.1.0 false schema multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {'schema': false},
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test('3.1.0 null multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {'type': 'null'},
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test(
    '3.1.0 multiple types multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': <String, dynamic>{},
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {
                    'type': ['string', 'object'],
                  },
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test('3.1.0 map multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'type': 'object',
                  'additionalProperties': {'type': 'string'},
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test(
    '3.1.0 referenced binary multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Binary': {'type': 'string', 'format': 'binary'},
            'BinaryAlias': {r'$ref': '#/components/schemas/Binary'},
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Binary'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.1.0 aliased binary multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Binary': {'type': 'string', 'format': 'binary'},
            'BinaryAlias': {r'$ref': '#/components/schemas/Binary'},
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/BinaryAlias'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.1.0 referenced map multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Map': {
              'type': 'object',
              'additionalProperties': {'type': 'string'},
            },
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Map'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.1.0 referenced composition multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Composed': {
              'allOf': [
                {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
                {
                  'type': 'object',
                  'properties': {
                    'count': {'type': 'integer'},
                  },
                },
              ],
            },
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Composed'},
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test(
    '3.1.0 annotated composition multipart root is kept for generation',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Composed': {
              'allOf': [
                {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
                {
                  'type': 'object',
                  'properties': {
                    'count': {'type': 'integer'},
                  },
                },
              ],
            },
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {
                    r'$ref': '#/components/schemas/Composed',
                    'description': 'Upload',
                    'nullable': true,
                  },
                },
              },
            },
          },
        },
      });

      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, isA<Model>());
      expect(content.contentType, ContentType.multipart);
    },
  );

  test('3.1.0 allOf multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'allOf': [
                    {'type': 'string'},
                  ],
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test('3.1.0 oneOf multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'oneOf': [
                    {'type': 'string'},
                    {'type': 'object'},
                  ],
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test('3.1.0 anyOf multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'anyOf': [
                    {'type': 'string'},
                    {'type': 'object'},
                  ],
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test('3.1.0 array multipart root is kept for generation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    expect(content.model, isA<Model>());
    expect(content.contentType, ContentType.multipart);
  });

  test('unresolved multipart schema references remain errors', () {
    final document = OpenApiObject.fromJson({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/Missing'},
              },
            },
          },
        },
      },
    });
    final examples = ExampleImporter(openApiObject: document);
    final models = ModelImporter(document, exampleImporter: examples)..import();
    final headers = ResponseHeaderImporter(
      openApiObject: document,
      modelImporter: models,
      exampleImporter: examples,
    )..import();
    final importer = RequestBodyImporter(
      openApiObject: document,
      modelImporter: models,
      contentTypes: const {},
      responseHeaderImporter: headers,
      exampleImporter: examples,
    );
    expect(importer.import, throwsArgumentError);
    expect(importer.requestBodies, isEmpty);
  });
}
