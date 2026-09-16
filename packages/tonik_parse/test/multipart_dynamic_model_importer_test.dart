import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('preserves the recursive map-array graph for multipart planning', () {
    final content = _import(
      '3.1.1',
      {r'$ref': '#/components/schemas/RecursiveMap'},
      schemas: {
        'RecursiveMap': {
          'type': 'object',
          'additionalProperties': {
            'type': 'array',
            'items': {r'$ref': '#/components/schemas/RecursiveMap'},
          },
        },
      },
    );
    final root = content.model.resolved as MapModel;
    expect(root.name, 'RecursiveMap');
    final children = root.valueModel.resolved as ListModel;
    expect(children.content.resolved, same(root));
  });

  test('OAS 3.0 keeps typed root maps and nullable inline values', () {
    final content = _import('3.0.4', {
      'type': 'object',
      'additionalProperties': {'type': 'string', 'nullable': true},
    });
    final map = content.model.resolved as MapModel;
    expect(map.valueModel.resolved, isA<StringModel>());
    expect(map.isValueNullable || map.valueModel.isEffectivelyNullable, isTrue);
    expect(content.encoding, isEmpty);
  });

  test('OAS 3.1 preserves referenced nullable roots and value aliases', () {
    final content = _import(
      '3.1.1',
      {r'$ref': '#/components/schemas/RootAlias'},
      schemas: {
        'Value': {
          'type': ['string', 'null'],
        },
        'Root': {
          'type': ['object', 'null'],
          'additionalProperties': {r'$ref': '#/components/schemas/Value'},
        },
        'RootAlias': {r'$ref': '#/components/schemas/Root'},
      },
    );
    expect(content.model, isA<AliasModel>());
    final root = content.model.resolved as MapModel;
    expect(root.isNullable, isTrue);
    expect(root.valueModel, isA<AliasModel>());
    expect(root.valueModel.isEffectivelyNullable, isTrue);
    expect(root.valueModel.resolved, isA<StringModel>());
  });

  test(
    'keeps mixed metadata and referenced file arrays on ordinary models',
    () {
      final content = _import(
        '3.0.4',
        {
          'type': 'object',
          'required': ['metadata', 'files'],
          'properties': {
            'metadata': {'type': 'string'},
          },
          'additionalProperties': {r'$ref': '#/components/schemas/Files'},
        },
        schemas: {
          'Files': {
            'type': 'array',
            'items': {'type': 'string', 'format': 'binary'},
          },
        },
      );
      final model = content.model.resolved as ClassModel;
      expect(model.properties.map((p) => p.name), ['metadata']);
      expect(model.properties.single.isRequired, isTrue);
      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.origin, AdditionalPropertiesOrigin.explicit);
      final files = policy.valueModel.resolved as ListModel;
      expect(files.name, 'Files');
      expect(files.content.resolved, isA<BinaryModel>());
    },
  );

  test('keeps binary and base64 references as their declared codecs', () {
    final content = _import(
      '3.1.1',
      {
        'type': 'object',
        'additionalProperties': {r'$ref': '#/components/schemas/Encoded'},
      },
      schemas: {
        'Encoded': {'type': 'string', 'contentEncoding': 'base64'},
      },
    );
    final model = content.model.resolved as MapModel;
    expect(model.valueModel.resolved, isA<Base64Model>());
  });

  test('preserves explicitly untyped map values for runtime rejection', () {
    final content = _import('3.1.1', {
      'type': 'object',
      'additionalProperties': true,
    });
    final model = content.model.resolved as MapModel;
    expect(model.valueModel.resolved, isA<AnyModel>());
  });

  test('preserves empty-schema additional properties as untyped values', () {
    final content = _import('3.0.4', {
      'type': 'object',
      'additionalProperties': <String, dynamic>{},
    });
    final model = content.model.resolved as MapModel;
    expect(model.valueModel.resolved, isA<AnyModel>());
  });

  test('bare open object roots remain untyped maps', () {
    final content = _import('3.1.1', {'type': 'object'});
    final model = content.model.resolved as MapModel;
    expect(model.valueModel.resolved, isA<AnyModel>());
  });

  test('an implicit policy keeps the ordinary named class API', () {
    final content = _import('3.1.1', {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
      },
    });
    final model = content.model.resolved as ClassModel;
    expect(model.properties.single.name, 'name');
    expect(
      (model.additionalPropertiesPolicy as AllowedAdditionalProperties).origin,
      AdditionalPropertiesOrigin.implicitDefault,
    );
  });

  test('forbidden additional properties retain the ordinary closed class', () {
    final content = _import('3.0.4', {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
      },
      'additionalProperties': false,
    });
    final model = content.model.resolved as ClassModel;
    expect(model.properties.single.name, 'name');
    expect(
      model.additionalPropertiesPolicy,
      isA<ForbiddenAdditionalProperties>(),
    );
  });

  test(
    'shared mixed schema identity is unchanged between JSON and multipart',
    () {
      final api = Importer().import({
        'openapi': '3.1.1',
        'info': {'title': 'Shared mixed', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Mixed': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
              'additionalProperties': {'type': 'integer'},
            },
          },
          'requestBodies': {
            'Upload': {
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Mixed'},
                },
                'application/json': {
                  'schema': {r'$ref': '#/components/schemas/Mixed'},
                },
              },
            },
          },
        },
      });
      final bodies = api.requestBodies.single.resolvedContent;
      final multipart = bodies.whereType<MultipartRequestContent>().single;
      final json = bodies.whereType<ModelRequestContent>().single;
      expect(multipart.model, same(json.model));
      final model = json.model as ClassModel;
      expect(
        (model.additionalPropertiesPolicy as AllowedAdditionalProperties)
            .valueModel,
        isA<IntegerModel>(),
      );
    },
  );
}

MultipartRequestContent _import(
  String version,
  Map<String, dynamic> schema, {
  Map<String, dynamic> schemas = const {},
}) {
  final api = Importer().import({
    'openapi': version,
    'info': {'title': 'Dynamic multipart', 'version': '1'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': schemas,
      'requestBodies': {
        'Upload': {
          'content': {
            'multipart/form-data': {'schema': schema},
          },
        },
      },
    },
  });
  return api.requestBodies.single.resolvedContent.single
      as MultipartRequestContent;
}
