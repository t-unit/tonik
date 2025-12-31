import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model_importer.dart';

void main() {
  group('ModelImporter boolean schemas', () {
    test('imports boolean schema true as AnyModel', () {
      final fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'AnyValue': true,
          },
        },
      };

      final openApiDoc = OpenApiObject.fromJson(fileContent);
      final modelImporter = ModelImporter(openApiDoc)..import();

      final model = modelImporter.models.whereType<NamedModel>().firstWhere(
        (m) => m.name == 'AnyValue',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.model, isA<AnyModel>());
    });

    test('imports boolean schema false as NeverModel', () {
      final fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'NeverValid': false,
          },
        },
      };

      final openApiDoc = OpenApiObject.fromJson(fileContent);
      final modelImporter = ModelImporter(openApiDoc)..import();

      final model = modelImporter.models.whereType<NamedModel>().firstWhere(
        (m) => m.name == 'NeverValid',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.model, isA<NeverModel>());
    });

    test('imports boolean schema in property', () {
      final fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'FlexibleObject': {
              'type': 'object',
              'properties': {
                'data': true, // Can be any value
                'never': false, // Never valid
              },
            },
          },
        },
      };

      final openApiDoc = OpenApiObject.fromJson(fileContent);
      final modelImporter = ModelImporter(openApiDoc)..import();

      final model = modelImporter.models.whereType<ClassModel>().firstWhere(
        (m) => m.name == 'FlexibleObject',
      );

      expect(model.properties.length, 2);

      final dataProperty = model.properties.firstWhere((p) => p.name == 'data');
      expect(dataProperty.model, isA<AnyModel>());

      final neverProperty = model.properties.firstWhere(
        (p) => p.name == 'never',
      );
      expect(neverProperty.model, isA<NeverModel>());
    });

    test('imports boolean schema in array items', () {
      final fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'FlexibleArray': {
              'type': 'array',
              'items': true,
            },
          },
        },
      };

      final openApiDoc = OpenApiObject.fromJson(fileContent);
      final modelImporter = ModelImporter(openApiDoc)..import();

      final model = modelImporter.models.whereType<NamedModel>().firstWhere(
        (m) => m.name == 'FlexibleArray',
      );

      expect(model, isA<ListModel>());
      final listModel = model as ListModel;
      expect(listModel.content, isA<AnyModel>());
      expect(listModel.name, 'FlexibleArray');
    });
  });
}
