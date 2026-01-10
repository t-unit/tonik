import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group(r'$defs parsing', () {
    test(r'parses $defs from schema JSON', () {
      final json = {
        'type': 'object',
        r'$defs': {
          'LineItem': {
            'type': 'object',
            'properties': {
              'product': {'type': 'string'},
              'quantity': {'type': 'integer'},
            },
          },
        },
        'properties': {
          'name': {'type': 'string'},
        },
      };

      final schema = Schema.fromJson(json);

      expect(schema.defs, isNotNull);
      expect(schema.defs, hasLength(1));
      expect(schema.defs!['LineItem'], isNotNull);
      expect(schema.defs!['LineItem']!.type, ['object']);
      expect(schema.defs!['LineItem']!.properties, hasLength(2));
    });

    test(r'parses nested $defs', () {
      final json = {
        'type': 'object',
        r'$defs': {
          'Outer': {
            'type': 'object',
            r'$defs': {
              'Inner': {
                'type': 'string',
              },
            },
          },
        },
      };

      final schema = Schema.fromJson(json);

      expect(schema.defs, isNotNull);
      expect(schema.defs!['Outer'], isNotNull);
      expect(schema.defs!['Outer']!.defs, isNotNull);
      expect(schema.defs!['Outer']!.defs!['Inner'], isNotNull);
      expect(schema.defs!['Outer']!.defs!['Inner']!.type, ['string']);
    });

    test(r'handles schema without $defs', () {
      final json = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
      };

      final schema = Schema.fromJson(json);

      expect(schema.defs, isNull);
    });

    test(r'handles empty $defs', () {
      final json = {
        'type': 'object',
        r'$defs': <String, dynamic>{},
      };

      final schema = Schema.fromJson(json);

      expect(schema.defs, isNotNull);
      expect(schema.defs, isEmpty);
    });
  });

  group(r'$defs reference resolution', () {
    test(r'resolves $ref to component schema $defs', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Order': {
              'type': 'object',
              r'$defs': {
                'LineItem': {
                  'type': 'object',
                  'properties': {
                    'product': {'type': 'string'},
                    'quantity': {'type': 'integer'},
                  },
                },
              },
              'properties': {
                'items': {
                  'type': 'array',
                  'items': {
                    r'$ref': r'#/components/schemas/Order/$defs/LineItem',
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final orderModel =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'Order',
              )
              as ClassModel;

      expect(orderModel, isNotNull);
      expect(orderModel.properties, hasLength(1));

      final itemsProperty = orderModel.properties.first;
      expect(itemsProperty.name, 'items');
      expect(itemsProperty.model, isA<ListModel>());

      final listModel = itemsProperty.model as ListModel;
      expect(listModel.content, isA<ClassModel>());

      final lineItemModel = listModel.content as ClassModel;
      expect(lineItemModel.properties, hasLength(2));
      expect(
        lineItemModel.properties.any((p) => p.name == 'product'),
        isTrue,
      );
      expect(
        lineItemModel.properties.any((p) => p.name == 'quantity'),
        isTrue,
      );
    });

    test(r'resolves $ref to namespace schema $defs', () {
      // Pattern: using a schema as a namespace container for $defs.
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'ns': {
              r'$defs': {
                'Foo': {
                  'type': 'object',
                  'properties': {
                    'bar': {'type': 'string'},
                  },
                },
              },
            },
            'MyModel': {
              'type': 'object',
              'properties': {
                'foo': {
                  r'$ref': r'#/components/schemas/ns/$defs/Foo',
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final myModel =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'MyModel',
              )
              as ClassModel;

      expect(myModel, isNotNull);
      expect(myModel.properties, hasLength(1));

      final fooProperty = myModel.properties.first;
      expect(fooProperty.name, 'foo');
      expect(fooProperty.model, isA<ClassModel>());

      final fooModel = fooProperty.model as ClassModel;
      expect(fooModel.properties, hasLength(1));
      expect(fooModel.properties.first.name, 'bar');
    });

    test(r'resolves $defs referencing other $defs', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Container': {
              'type': 'object',
              r'$defs': {
                'Inner': {
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'string'},
                  },
                },
                'Outer': {
                  'type': 'object',
                  'properties': {
                    'inner': {
                      r'$ref': r'#/components/schemas/Container/$defs/Inner',
                    },
                  },
                },
              },
              'properties': {
                'data': {
                  r'$ref': r'#/components/schemas/Container/$defs/Outer',
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final containerModel =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'Container',
              )
              as ClassModel;

      expect(containerModel, isNotNull);
      expect(containerModel.properties, hasLength(1));

      final dataProperty = containerModel.properties.first;
      expect(dataProperty.name, 'data');
      expect(dataProperty.model, isA<ClassModel>());

      final outerModel = dataProperty.model as ClassModel;
      expect(outerModel.properties, hasLength(1));

      final innerProperty = outerModel.properties.first;
      expect(innerProperty.name, 'inner');
      expect(innerProperty.model, isA<ClassModel>());

      final innerModel = innerProperty.model as ClassModel;
      expect(innerModel.properties, hasLength(1));
      expect(innerModel.properties.first.name, 'value');
    });

    test(r'ignores unused $defs', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'MySchema': {
              'type': 'object',
              r'$defs': {
                'Unused': {
                  'type': 'object',
                  'properties': {
                    'foo': {'type': 'string'},
                  },
                },
              },
              'properties': {
                'name': {'type': 'string'},
              },
            },
          },
        },
      };

      // Should not throw and should not create a model for Unused.
      final api = Importer().import(fileContent);

      final mySchema =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'MySchema',
              )
              as ClassModel;

      expect(mySchema, isNotNull);
      expect(mySchema.properties, hasLength(1));
      expect(mySchema.properties.first.name, 'name');

      // Unused $defs should not be in the models.
      final unusedModel = api.models.where(
        (m) => m is NamedModel && m.name == 'Unused',
      );
      expect(unusedModel, isEmpty);
    });

    test(r'resolves $defs from operation request body', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/orders': {
            'post': {
              'operationId': 'createOrder',
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {
                      r'$ref': r'#/components/schemas/ns/$defs/OrderInput',
                    },
                  },
                },
              },
              'responses': {
                '200': {
                  'description': 'OK',
                },
              },
            },
          },
        },
        'components': {
          'schemas': {
            'ns': {
              r'$defs': {
                'OrderInput': {
                  'type': 'object',
                  'properties': {
                    'customerId': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final operation = api.operations.first;
      expect(operation.operationId, 'createOrder');

      final requestBody = operation.requestBody;
      expect(requestBody, isNotNull);

      final jsonContent = requestBody!.resolvedContent.firstWhere(
        (RequestContent c) => c.contentType == ContentType.json,
      );
      expect(jsonContent.model, isA<ClassModel>());

      final orderInputModel = jsonContent.model as ClassModel;
      expect(orderInputModel.properties, hasLength(1));
      expect(orderInputModel.properties.first.name, 'customerId');
    });

    test(r'resolves $defs from operation response', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/orders/{id}': {
            'get': {
              'operationId': 'getOrder',
              'parameters': [
                {
                  'name': 'id',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        r'$ref': r'#/components/schemas/ns/$defs/OrderOutput',
                      },
                    },
                  },
                },
              },
            },
          },
        },
        'components': {
          'schemas': {
            'ns': {
              r'$defs': {
                'OrderOutput': {
                  'type': 'object',
                  'properties': {
                    'id': {'type': 'string'},
                    'status': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final operation = api.operations.first;
      expect(operation.operationId, 'getOrder');

      final response = operation.responses.values.first.resolved;
      expect(response.bodies, isNotEmpty);

      final jsonBody = response.bodies.firstWhere(
        (ResponseBody b) => b.contentType == ContentType.json,
      );
      expect(jsonBody.model, isA<ClassModel>());

      final orderOutputModel = jsonBody.model as ClassModel;
      expect(orderOutputModel.properties, hasLength(2));
    });

    test(r'resolves mixed $defs and component schema $ref', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'User': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'ns': {
              r'$defs': {
                'Order': {
                  'type': 'object',
                  'properties': {
                    'user': {
                      r'$ref': '#/components/schemas/User',
                    },
                    'total': {'type': 'number'},
                  },
                },
              },
            },
            'Invoice': {
              'type': 'object',
              'properties': {
                'order': {
                  r'$ref': r'#/components/schemas/ns/$defs/Order',
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final invoiceModel =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'Invoice',
              )
              as ClassModel;

      final orderProperty = invoiceModel.properties.first;
      expect(orderProperty.model, isA<ClassModel>());

      final orderModel = orderProperty.model as ClassModel;
      expect(orderModel.properties, hasLength(2));

      final userProperty = orderModel.properties.firstWhere(
        (p) => p.name == 'user',
      );
      // User reference should resolve to the component schema.
      expect(userProperty.model, isA<ClassModel>());
      expect((userProperty.model as ClassModel).properties.first.name, 'name');
    });
  });
}
