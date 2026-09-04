import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('reuses regular schemas aliases defs and reusable request bodies', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Shared': {
            'type': 'object',
            'required': ['display-name'],
            'properties': {
              'display-name': {
                'type': ['string', 'null'],
                'description': 'A shared field',
              },
            },
            r'$defs': {
              'Nested': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'integer'},
                },
              },
            },
          },
          'SharedAlias': {r'$ref': '#/components/schemas/Shared'},
        },
        'requestBodies': {
          'Multipart': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/Shared'},
                'example': {'display-name': 'example'},
              },
            },
          },
          'MultipartAlias': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/SharedAlias'},
                'example': {'display-name': 'example'},
              },
            },
          },
          'FromDefs': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {
                  r'$ref': r'#/components/schemas/Shared/$defs/Nested',
                },
                'example': {'display-name': 'example'},
              },
            },
          },
          'Reusable': {r'$ref': '#/components/requestBodies/Multipart'},
        },
      },
    });

    final shared = api.models.singleWhere(
      (model) => model is NamedModel && model.name == 'Shared',
    );
    final alias =
        api.models.singleWhere(
              (model) => model is NamedModel && model.name == 'SharedAlias',
            )
            as AliasModel;
    final nested = api.models.singleWhere(
      (model) => model is NamedModel && model.name == 'Nested',
    );
    final multipart =
        api.requestBodies
                .singleWhere((body) => body.name == 'Multipart')
                .resolvedContent
                .single
            as MultipartRequestContent;
    final aliasContent =
        api.requestBodies
                .singleWhere((body) => body.name == 'MultipartAlias')
                .resolvedContent
                .single
            as MultipartRequestContent;
    final defsContent =
        api.requestBodies
                .singleWhere((body) => body.name == 'FromDefs')
                .resolvedContent
                .single
            as MultipartRequestContent;
    final reusable = api.requestBodies.singleWhere(
      (body) => body.name == 'Reusable',
    );
    expect(alias.model, same(shared));
    expect(multipart.model, same(shared));
    expect(aliasContent.model, same(alias));
    expect(defsContent.model, same(nested));
    expect(reusable, isA<RequestBodyAlias>());
    expect(reusable.resolvedContent.single, same(multipart));
    expect(multipart.model, isA<ClassModel>());
  });

  test('keeps multipart encodings on each use of a shared JSON model', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': {
        '/first': {
          'post': {
            'requestBody': {r'$ref': '#/components/requestBodies/Multipart'},
            'responses': {
              '204': {'description': 'Accepted'},
            },
          },
        },
        '/second': {
          'post': {
            'requestBody': {
              r'$ref': '#/components/requestBodies/OtherMultipart',
            },
            'responses': {
              '204': {'description': 'Accepted'},
            },
          },
        },
      },
      'components': {
        'schemas': {
          'Shared': {
            'type': 'object',
            'required': ['display-name'],
            'properties': {
              'display-name': {
                'type': ['string', 'null'],
                'description': 'A shared field',
              },
            },
            r'$defs': {
              'Nested': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'integer'},
                },
              },
            },
          },
        },
        'requestBodies': {
          'Multipart': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/Shared'},
                'example': {'display-name': 'example'},
                'encoding': {
                  'display-name': {
                    'contentType': 'text/plain',
                    'style': 'form',
                    'explode': false,
                    'allowReserved': true,
                    'headers': {
                      'X-Label': {
                        'required': true,
                        'schema': {'type': 'string'},
                      },
                    },
                  },
                },
              },
            },
          },
          'OtherMultipart': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/Shared'},
                'example': {'display-name': 'example'},
                'encoding': {
                  'display-name': {'contentType': 'application/json'},
                },
              },
            },
          },
          'Json': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {r'$ref': '#/components/schemas/Shared'},
                'example': {'display-name': 'example'},
              },
            },
          },
        },
        'responses': {
          'SharedResponse': {
            'description': 'Shared response',
            'content': {
              'application/json': {
                'schema': {r'$ref': '#/components/schemas/Shared'},
              },
            },
          },
        },
      },
    });

    final first =
        api.requestBodies
                .singleWhere((body) => body.name == 'Multipart')
                .resolvedContent
                .single
            as MultipartRequestContent;
    final second =
        api.requestBodies
                .singleWhere((body) => body.name == 'OtherMultipart')
                .resolvedContent
                .single
            as MultipartRequestContent;
    final shared = api.models.singleWhere(
      (model) => model is NamedModel && model.name == 'Shared',
    );
    final jsonBody =
        api.requestBodies
                .singleWhere((body) => body.name == 'Json')
                .resolvedContent
                .single
            as ModelRequestContent;
    final response = api.responses
        .singleWhere((response) => response.name == 'SharedResponse')
        .resolved
        .bodies
        .single;
    expect(first.model, same(shared));
    expect(second.model, same(shared));
    expect(jsonBody.model, same(shared));
    expect(response.model, same(shared));
    expect(first.encoding['display-name']!.rawContentType, 'text/plain');
    expect(second.encoding['display-name']!.rawContentType, 'application/json');
    expect(first.encoding, isNot(same(second.encoding)));
    expect(jsonBody.formEncoding, isNull);
    final operations = api.operations.toList();
    expect(operations, hasLength(2));
    expect(operations[0].requestBody!.resolvedContent.single, same(first));
    expect(operations[1].requestBody!.resolvedContent.single, same(second));
    final property = (shared as ClassModel).properties.single;
    expect(property.name, 'display-name');
    expect(property.isRequired, isTrue);
    expect(property.description, 'A shared field');
    expect(property.isNullable, isTrue);
  });

  test('imports declared encoding headers media types and examples', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Shared': {
            'type': 'object',
            'required': ['display-name'],
            'properties': {
              'display-name': {
                'type': ['string', 'null'],
                'description': 'A shared field',
              },
            },
            r'$defs': {
              'Nested': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'integer'},
                },
              },
            },
          },
        },
        'requestBodies': {
          'Multipart': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/Shared'},
                'example': {'display-name': 'example'},
                'encoding': {
                  'display-name': {
                    'contentType': 'text/plain',
                    'style': 'form',
                    'explode': false,
                    'allowReserved': true,
                    'headers': {
                      'X-Label': {
                        'required': true,
                        'schema': {'type': 'string'},
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies
                .singleWhere((body) => body.name == 'Multipart')
                .resolvedContent
                .single
            as MultipartRequestContent;
    expect(content.rawContentType, 'multipart/form-data');
    expect(content.examples.single.value, {'display-name': 'example'});
    final encoding = content.encoding['display-name'];
    expect(encoding, isNotNull);
    expect(encoding!.rawContentType, 'text/plain');
    expect(encoding.style, EncodingStyle.form);
    expect(encoding.explode, isFalse);
    expect(encoding.allowReserved, isTrue);
    final header = encoding.headers!['X-Label']!.resolve();
    expect(header.model, isA<StringModel>());
    expect(header.isRequired, isTrue);
  });

  test('leaves absent model dependent encoding defaults to generation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Shared': {
            'type': 'object',
            'required': ['display-name'],
            'properties': {
              'display-name': {
                'type': ['string', 'null'],
                'description': 'A shared field',
              },
            },
            r'$defs': {
              'Nested': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'integer'},
                },
              },
            },
          },
          'SharedAlias': {r'$ref': '#/components/schemas/Shared'},
        },
        'requestBodies': {
          'MultipartAlias': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/SharedAlias'},
                'example': {'display-name': 'example'},
              },
            },
          },
        },
      },
    });

    final content =
        api.requestBodies
                .singleWhere((body) => body.name == 'MultipartAlias')
                .resolvedContent
                .single
            as MultipartRequestContent;
    expect(content.encoding, isEmpty);
  });

  test('preserves allOf roots and duplicate properties for generation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Zebra': {
            'type': 'object',
            'properties': {
              'metadata': {
                'type': 'object',
                'properties': {
                  'base': {'type': 'string'},
                },
              },
            },
          },
          'Alpha': {
            'type': 'object',
            'properties': {
              'metadata': {
                'type': 'object',
                'properties': {
                  'extra': {'type': 'string'},
                },
              },
            },
          },
          'Composed': {
            'allOf': [
              {r'$ref': '#/components/schemas/Zebra'},
              {r'$ref': '#/components/schemas/Alpha'},
            ],
          },
        },
        'requestBodies': {
          'Composed': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/Composed'},
                'example': {'display-name': 'example'},
              },
            },
          },
        },
      },
    });

    final model =
        api.models.singleWhere(
              (model) => model is NamedModel && model.name == 'Composed',
            )
            as AllOfModel;
    final content =
        api.requestBodies
                .singleWhere((body) => body.name == 'Composed')
                .resolvedContent
                .single
            as MultipartRequestContent;
    final zebra =
        api.models.singleWhere(
              (model) => model is NamedModel && model.name == 'Zebra',
            )
            as ClassModel;
    final alpha =
        api.models.singleWhere(
              (model) => model is NamedModel && model.name == 'Alpha',
            )
            as ClassModel;
    expect(content.model, same(model));
    final members = model.models;
    expect(members, isA<List<Model>>());
    expect(members, [zebra, alpha]);
    expect(zebra.properties.single.name, 'metadata');
    expect(alpha.properties.single.name, 'metadata');
    expect(api.models.whereType<AllOfModel>(), hasLength(1));
  });

  test('preserves oneOf roots and duplicate properties for generation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Zebra': {
            'type': 'object',
            'properties': {
              'metadata': {
                'type': 'object',
                'properties': {
                  'base': {'type': 'string'},
                },
              },
            },
          },
          'Alpha': {
            'type': 'object',
            'properties': {
              'metadata': {
                'type': 'object',
                'properties': {
                  'extra': {'type': 'string'},
                },
              },
            },
          },
          'Composed': {
            'oneOf': [
              {r'$ref': '#/components/schemas/Zebra'},
              {r'$ref': '#/components/schemas/Alpha'},
            ],
          },
        },
        'requestBodies': {
          'Composed': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/Composed'},
                'example': {'display-name': 'example'},
              },
            },
          },
        },
      },
    });

    final model =
        api.models.singleWhere(
              (model) => model is NamedModel && model.name == 'Composed',
            )
            as OneOfModel;
    final content =
        api.requestBodies
                .singleWhere((body) => body.name == 'Composed')
                .resolvedContent
                .single
            as MultipartRequestContent;
    final zebra =
        api.models.singleWhere(
              (model) => model is NamedModel && model.name == 'Zebra',
            )
            as ClassModel;
    final alpha =
        api.models.singleWhere(
              (model) => model is NamedModel && model.name == 'Alpha',
            )
            as ClassModel;
    expect(content.model, same(model));
    final members = model.models.map((member) => member.model).toList();
    expect(members, isA<List<Model>>());
    expect(members, [zebra, alpha]);
    expect(zebra.properties.single.name, 'metadata');
    expect(alpha.properties.single.name, 'metadata');
    expect(api.models.whereType<AllOfModel>(), hasLength(0));
  });

  test('preserves anyOf roots and duplicate properties for generation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Zebra': {
            'type': 'object',
            'properties': {
              'metadata': {
                'type': 'object',
                'properties': {
                  'base': {'type': 'string'},
                },
              },
            },
          },
          'Alpha': {
            'type': 'object',
            'properties': {
              'metadata': {
                'type': 'object',
                'properties': {
                  'extra': {'type': 'string'},
                },
              },
            },
          },
          'Composed': {
            'anyOf': [
              {r'$ref': '#/components/schemas/Zebra'},
              {r'$ref': '#/components/schemas/Alpha'},
            ],
          },
        },
        'requestBodies': {
          'Composed': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/Composed'},
                'example': {'display-name': 'example'},
              },
            },
          },
        },
      },
    });

    final model =
        api.models.singleWhere(
              (model) => model is NamedModel && model.name == 'Composed',
            )
            as AnyOfModel;
    final content =
        api.requestBodies
                .singleWhere((body) => body.name == 'Composed')
                .resolvedContent
                .single
            as MultipartRequestContent;
    final zebra =
        api.models.singleWhere(
              (model) => model is NamedModel && model.name == 'Zebra',
            )
            as ClassModel;
    final alpha =
        api.models.singleWhere(
              (model) => model is NamedModel && model.name == 'Alpha',
            )
            as ClassModel;
    expect(content.model, same(model));
    final members = model.models.map((member) => member.model).toList();
    expect(members, isA<List<Model>>());
    expect(members, [zebra, alpha]);
    expect(zebra.properties.single.name, 'metadata');
    expect(alpha.properties.single.name, 'metadata');
    expect(api.models.whereType<AllOfModel>(), hasLength(0));
  });

  test('retains normal unresolved schema reference failures', () {
    final document = {
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': <String, dynamic>{},
        'requestBodies': {
          'Upload': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/Missing'},
                'example': {'display-name': 'example'},
              },
            },
          },
        },
      },
    };
    expect(() => Importer().import(document), throwsA(anything));
  });

  test(
    'retains regular alias models and terminal for bare reference cycles',
    () {
      final document = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Missing': {r'$ref': '#/components/schemas/Other'},
            'Other': {r'$ref': '#/components/schemas/Missing'},
          },
          'requestBodies': {
            'Upload': {
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Missing'},
                  'example': {'display-name': 'example'},
                },
              },
            },
          },
        },
      };
      final api = Importer().import(document);
      final missing = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Missing',
      );
      final other = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Other',
      );
      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      expect(content.model, same(missing));
      expect(missing.model, same(other));
      expect(other.model, isA<AnyModel>());
    },
  );
}
