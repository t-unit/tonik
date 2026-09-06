import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model_importer.dart';
import 'package:tonik_parse/src/request_body_importer.dart';
import 'package:tonik_parse/src/response_header_importer.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('multipart parsing retains unsupported roots as regular models', () {
    for (final version in ['3.0.3', '3.1.0']) {
      for (final entry in _unsupportedRoots.entries) {
        final api = Importer().import(_document(entry.value.schema, version));
        final content =
            api.requestBodies.single.resolvedContent.single
                as MultipartRequestContent;
        expect(content.contentType, ContentType.multipart);
        expect(
          content.model.resolved.runtimeType,
          entry.value.resolvedType,
          reason: '$version: ${entry.key}',
        );
      }
    }
  });

  test('unresolved multipart schema references remain errors', () {
    final document = OpenApiObject.fromJson(
      _document({r'$ref': '#/components/schemas/Missing'}, '3.1.0'),
    );
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

const _unsupportedRoots = <String, ({Object? schema, Type resolvedType})>{
  'missing schema': (schema: null, resolvedType: AnyModel),
  'string': (schema: {'type': 'string'}, resolvedType: StringModel),
  'integer': (schema: {'type': 'integer'}, resolvedType: IntegerModel),
  'boolean': (schema: {'type': 'boolean'}, resolvedType: BooleanModel),
  'boolean schema': (schema: true, resolvedType: AnyModel),
  'false schema': (schema: false, resolvedType: NeverModel),
  'null': (schema: {'type': 'null'}, resolvedType: NeverModel),
  'multiple types': (
    schema: {
      'type': ['string', 'object'],
    },
    resolvedType: OneOfModel,
  ),
  'map': (
    schema: {
      'type': 'object',
      'additionalProperties': {'type': 'string'},
    },
    resolvedType: MapModel,
  ),
  'referenced binary': (
    schema: {r'$ref': '#/components/schemas/Binary'},
    resolvedType: BinaryModel,
  ),
  'aliased binary': (
    schema: {r'$ref': '#/components/schemas/BinaryAlias'},
    resolvedType: BinaryModel,
  ),
  'referenced map': (
    schema: {r'$ref': '#/components/schemas/Map'},
    resolvedType: MapModel,
  ),
  'referenced composition': (
    schema: {r'$ref': '#/components/schemas/Composed'},
    resolvedType: AllOfModel,
  ),
  'annotated composition': (
    schema: {
      r'$ref': '#/components/schemas/Composed',
      'description': 'Upload',
      'nullable': true,
    },
    resolvedType: AllOfModel,
  ),
  'allOf': (
    schema: {
      'allOf': [
        {'type': 'string'},
      ],
    },
    resolvedType: AllOfModel,
  ),
  'oneOf': (
    schema: {
      'oneOf': [
        {'type': 'string'},
        {'type': 'object'},
      ],
    },
    resolvedType: OneOfModel,
  ),
  'anyOf': (
    schema: {
      'anyOf': [
        {'type': 'string'},
        {'type': 'object'},
      ],
    },
    resolvedType: AnyOfModel,
  ),
  'array': (
    schema: {
      'type': 'array',
      'items': {'type': 'string'},
    },
    resolvedType: ListModel,
  ),
};

Map<String, dynamic> _document(Object? schema, String version) => {
  'openapi': version,
  'info': {'title': 'Multipart roots', 'version': '1.0.0'},
  'paths': <String, dynamic>{},
  'components': {
    'schemas': {
      'Binary': {'type': 'string', 'format': 'binary'},
      'BinaryAlias': {r'$ref': '#/components/schemas/Binary'},
      'Map': {
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      },
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
          'multipart/form-data': {'schema': ?schema},
        },
      },
    },
  },
};
