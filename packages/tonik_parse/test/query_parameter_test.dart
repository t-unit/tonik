import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.4',
    'info': {'title': 'Query Parameter Encoding API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'parameters': {
        'colorForm': {
          'name': 'colorForm',
          'in': 'query',
          'style': 'form',
          'explode': false,
          'schema': {'type': 'string'},
        },
        'colorSpaceDelimited': {
          'name': 'colorSpaceDelimited',
          'in': 'query',
          'style': 'spaceDelimited',
          'explode': false,
          'schema': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'colorPipeDelimited': {
          'name': 'colorPipeDelimited',
          'in': 'query',
          'deprecated': true,
          'required': true,
          'style': 'pipeDelimited',
          'explode': false,
          'schema': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'colorDeepObject': {
          'name': 'colorDeepObject',
          'in': 'query',
          'style': 'deepObject',
          'explode': true,
          'schema': {
            'type': 'object',
            'properties': {
              'r': {'type': 'string'},
              'g': {'type': 'string'},
              'b': {'type': 'string'},
            },
          },
        },
        'colorSchema': {
          'name': 'colorSchema',
          'in': 'query',
          'schema': {r'$ref': '#/components/schemas/Color'},
        },
        'colorReference': {r'$ref': '#/components/parameters/colorSchema'},
      },
      'schemas': {
        'Color': {
          'type': 'object',
          'properties': {
            'r': {'type': 'string'},
            'b': {'type': 'string'},
          },
        },
      },
    },
  };
  final api = Importer().import(fileContent);
  final queryParameters = api.queryParameters;

  test('imports form style query parameter', () {
    final parameter = queryParameters
        .whereType<QueryParameterObject>()
        .firstWhere((p) => p.name == 'colorForm');

    expect(parameter.rawName, 'colorForm');
    expect(parameter.description, isNull);
    expect(parameter.isRequired, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.allowEmptyValue, isFalse);
    expect(parameter.allowReserved, isFalse);
    expect(parameter.explode, isFalse);
    expect(parameter.model, isA<StringModel>());
    expect(parameter.encoding, QueryParameterEncoding.form);
  });

  test('imports space delimited style query parameter', () {
    final parameter = queryParameters
        .whereType<QueryParameterObject>()
        .firstWhere((p) => p.name == 'colorSpaceDelimited');

    expect(parameter.rawName, 'colorSpaceDelimited');
    expect(parameter.description, isNull);
    expect(parameter.isRequired, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.allowEmptyValue, isFalse);
    expect(parameter.allowReserved, isFalse);
    expect(parameter.explode, isFalse);
    expect(parameter.model, isA<ListModel>());
    expect(parameter.encoding, QueryParameterEncoding.spaceDelimited);
  });

  test('imports pipe delimited style query parameter', () {
    final parameter = queryParameters
        .whereType<QueryParameterObject>()
        .firstWhere((p) => p.name == 'colorPipeDelimited');

    expect(parameter.rawName, 'colorPipeDelimited');
    expect(parameter.description, isNull);
    expect(parameter.isRequired, isTrue);
    expect(parameter.isDeprecated, isTrue);
    expect(parameter.allowEmptyValue, isFalse);
    expect(parameter.allowReserved, isFalse);
    expect(parameter.explode, isFalse);
    expect(parameter.model, isA<ListModel>());
    expect(parameter.encoding, QueryParameterEncoding.pipeDelimited);
  });

  test('imports deep object style query parameter', () {
    final parameter = queryParameters
        .whereType<QueryParameterObject>()
        .firstWhere((p) => p.name == 'colorDeepObject');

    expect(parameter.rawName, 'colorDeepObject');
    expect(parameter.description, isNull);
    expect(parameter.isRequired, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.allowEmptyValue, isFalse);
    expect(parameter.allowReserved, isFalse);
    expect(parameter.explode, isTrue);
    expect(parameter.model, isA<ClassModel>());
    expect(parameter.encoding, QueryParameterEncoding.deepObject);

    final classModel = parameter.model as ClassModel;
    expect(classModel.properties.length, 3);
    expect(
      classModel.properties.firstWhere((p) => p.name == 'r').model,
      isA<StringModel>(),
    );
    expect(
      classModel.properties.firstWhere((p) => p.name == 'g').model,
      isA<StringModel>(),
    );
    expect(
      classModel.properties.firstWhere((p) => p.name == 'b').model,
      isA<StringModel>(),
    );
  });

  test('imports schema style query parameter', () {
    final parameter = queryParameters
        .whereType<QueryParameterObject>()
        .firstWhere((p) => p.name == 'colorSchema');

    expect(parameter.rawName, 'colorSchema');
    expect(parameter.description, isNull);
    expect(parameter.isRequired, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.allowEmptyValue, isFalse);
    expect(parameter.allowReserved, isFalse);
    expect(parameter.explode, isFalse);
    expect(parameter.model, isA<ClassModel>());
    expect(parameter.encoding, QueryParameterEncoding.form);

    final classModel = parameter.model as ClassModel;
    expect(classModel.properties.length, 2);
    expect(
      classModel.properties.firstWhere((p) => p.name == 'r').model,
      isA<StringModel>(),
    );
    expect(
      classModel.properties.firstWhere((p) => p.name == 'b').model,
      isA<StringModel>(),
    );

    expect(api.models, contains(classModel));
  });

  test('imports reference query parameter', () {
    final parameter = queryParameters
        .whereType<QueryParameterAlias>()
        .firstWhere((p) => p.name == 'colorReference');

    final reference = queryParameters
        .whereType<QueryParameterObject>()
        .firstWhere((p) => p.name == 'colorSchema');

    expect(parameter.parameter, reference);
  });

  test('does not import header references as query parameters', () {
    final parameter = queryParameters
        .whereType<QueryParameterAlias>()
        .firstWhereOrNull((p) => p.name == 'headerReference');

    expect(parameter, isNull);
  });
}
