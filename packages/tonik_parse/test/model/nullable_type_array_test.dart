import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('named arrays retain null from a type array', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'NullableTags': {
            'type': ['array', 'null'],
            'items': {'type': 'string'},
          },
          'Tags': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
      },
    });

    final nullable = api.models.whereType<ListModel>().singleWhere(
      (model) => model.name == 'NullableTags',
    );
    final required = api.models.whereType<ListModel>().singleWhere(
      (model) => model.name == 'Tags',
    );
    expect(nullable.isNullable, isTrue);
    expect(nullable.isEffectivelyNullable, isTrue);
    expect(nullable.content, isA<StringModel>());
    expect(nullable.isContentNullable, isFalse);
    expect(required.isNullable, isFalse);
  });

  test(
    'inline array and multi-type response bodies retain their null type',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/tags': {
            'get': {
              'operationId': 'tags',
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': ['array', 'null'],
                        'items': {'type': 'string'},
                      },
                    },
                  },
                },
              },
            },
          },
          '/value': {
            'get': {
              'operationId': 'value',
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': ['string', 'integer', 'null'],
                      },
                    },
                  },
                },
              },
            },
          },
        },
      });

      final tags =
          api.operations
                  .singleWhere((operation) => operation.operationId == 'tags')
                  .responses
                  .values
                  .single
                  .resolved
                  .bodies
                  .single
                  .model
              as ListModel;
      final value =
          api.operations
                  .singleWhere((operation) => operation.operationId == 'value')
                  .responses
                  .values
                  .single
                  .resolved
                  .bodies
                  .single
                  .model
              as OneOfModel;
      expect(tags.isNullable, isTrue);
      expect(value.isNullable, isTrue);
      expect(value.models.first.model, isA<StringModel>());
      expect(value.models.last.model, isA<IntegerModel>());
    },
  );

  test('named multi-type nullability and nonnullable unions remain intact', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'NullableValue': {
            'type': ['string', 'integer', 'null'],
          },
          'Value': {
            'type': ['string', 'integer'],
          },
          'Holder': {
            'type': 'object',
            'properties': {
              'value': {
                'type': ['string', 'integer'],
              },
            },
          },
        },
      },
    });

    final nullable = api.models.whereType<OneOfModel>().singleWhere(
      (model) => model.name == 'NullableValue',
    );
    final required = api.models.whereType<OneOfModel>().singleWhere(
      (model) => model.name == 'Value',
    );
    final holder = api.models.whereType<ClassModel>().single;
    final inline = holder.properties.single.model as OneOfModel;
    expect(nullable.isNullable, isTrue);
    expect(required.isNullable, isFalse);
    expect(inline.isNullable, isFalse);
  });

  test('OpenAPI 3.0 nullable arrays remain nullable', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Tags': {
            'type': 'array',
            'nullable': true,
            'items': {'type': 'string'},
          },
        },
      },
    });

    final tags = api.models.whereType<ListModel>().single;
    expect(tags.isNullable, isTrue);
    expect(tags.isContentNullable, isFalse);
  });
}
