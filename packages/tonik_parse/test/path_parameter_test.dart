import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.4',
    'info': {'title': 'Path Parameter Encoding API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'parameters': {
        'userIdMatrix': {
          'name': 'userId',
          'in': 'path',
          'style': 'matrix',
          'explode': false,
          'schema': {'type': 'string'},
        },
        'userIdLabel': {
          'name': 'userId2',
          'in': 'path',
          'style': 'label',
          'explode': false,
          'schema': {'type': 'string'},
        },
        'userIdSimple': {
          'name': 'userId3',
          'description': 'Simple style path parameter',
          'in': 'path',
          'style': 'simple',
          'explode': false,
          'schema': {'type': 'string'},
        },
        'userIdSchema': {
          'name': 'userId8',
          'in': 'path',
          'schema': {r'$ref': '#/components/schemas/UserId'},
        },
        'userIdReference': {r'$ref': '#/components/parameters/userIdMatrix'},
      },
      'schemas': {
        'UserId': {
          'type': 'object',
          'properties': {
            'id': {'type': 'string'},
            'type': {'type': 'string'},
          },
        },
      },
    },
  };
  final api = Importer().import(fileContent);
  final pathParameters = api.pathParameters;

  test('imports matrix style path parameter', () {
    final parameter = pathParameters
        .whereType<PathParameterObject>()
        .firstWhere((p) => p.name == 'userIdMatrix');

    expect(parameter.rawName, 'userId');
    expect(parameter.description, isNull);
    expect(parameter.isRequired, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.allowEmptyValue, isFalse);
    expect(parameter.explode, isFalse);
    expect(parameter.model, isA<StringModel>());
    expect(parameter.encoding, PathParameterEncoding.matrix);
  });

  test('imports label style path parameter', () {
    final parameter = pathParameters
        .whereType<PathParameterObject>()
        .firstWhere((p) => p.name == 'userIdLabel');

    expect(parameter.rawName, 'userId2');
    expect(parameter.description, isNull);
    expect(parameter.isRequired, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.allowEmptyValue, isFalse);
    expect(parameter.explode, isFalse);
    expect(parameter.model, isA<StringModel>());
    expect(parameter.encoding, PathParameterEncoding.label);
  });

  test('imports simple style path parameter', () {
    final parameter = pathParameters
        .whereType<PathParameterObject>()
        .firstWhere((p) => p.name == 'userIdSimple');

    expect(parameter.rawName, 'userId3');
    expect(parameter.description, 'Simple style path parameter');
    expect(parameter.isRequired, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.allowEmptyValue, isFalse);
    expect(parameter.explode, isFalse);
    expect(parameter.model, isA<StringModel>());
    expect(parameter.encoding, PathParameterEncoding.simple);
  });

  test('imports schema style path parameter', () {
    final parameter = pathParameters
        .whereType<PathParameterObject>()
        .firstWhere((p) => p.name == 'userIdSchema');

    expect(parameter.rawName, 'userId8');
    expect(parameter.description, isNull);
    expect(parameter.isRequired, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.allowEmptyValue, isFalse);
    expect(parameter.explode, isFalse);
    expect(parameter.model, isA<ClassModel>());
    expect(parameter.encoding, PathParameterEncoding.simple);

    final classModel = parameter.model as ClassModel;
    expect(classModel.properties.length, 2);
    expect(
      classModel.properties.firstWhere((p) => p.name == 'id').model,
      isA<StringModel>(),
    );
    expect(
      classModel.properties.firstWhere((p) => p.name == 'type').model,
      isA<StringModel>(),
    );

    expect(api.models, contains(classModel));
  });

  test('imports reference path parameter', () {
    final parameter = pathParameters.whereType<PathParameterAlias>().firstWhere(
      (p) => p.name == 'userIdReference',
    );

    final reference = pathParameters
        .whereType<PathParameterObject>()
        .firstWhere((p) => p.name == 'userIdMatrix');

    expect(parameter.parameter, reference);
  });

  test('does not import header references as path parameters', () {
    final parameter = pathParameters
        .whereType<PathParameterAlias>()
        .firstWhereOrNull((p) => p.name == 'headerReference');

    expect(parameter, isNull);
  });
}
