import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model_importer.dart';
import 'package:tonik_parse/src/request_body_importer.dart';
import 'package:tonik_parse/src/response_header_importer.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('unsupported multipart roots warn and produce an empty body', () {
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);
    addTearDown(subscription.cancel);
    for (final version in ['3.0.3', '3.1.0']) {
      for (final entry in _unsupportedRoots.entries) {
        records.clear();
        final api = Importer().import(_document(entry.value, version));
        final content =
            api.requestBodies.single.resolvedContent.single
                as MultipartRequestContent;
        expect(content.parts, isEmpty, reason: '$version: ${entry.key}');
        expect(content.contentType, ContentType.multipart);
        expect(content.name, isNull);
        expect(content.sourceName, isNull);
        expect(content.alias, isNull);
        expect(content.sourceContext, content.context);
        expect(
          content.context,
          RequestBodyImporter.rootContext.pushAll(['Upload', 'body']),
        );
        expect(
          content.additionalPropertiesPolicy,
          isA<ForbiddenAdditionalProperties>(),
        );
        expect(
          records
              .singleWhere((record) => record.level == Level.WARNING)
              .message,
          'Multipart body at components/requestBodies/Upload has an unsupported or missing root schema. '
          'Generating an empty multipart body.',
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

const _unsupportedRoots = <String, Object?>{
  'missing schema': null,
  'string': {'type': 'string'},
  'integer': {'type': 'integer'},
  'boolean': {'type': 'boolean'},
  'boolean schema': true,
  'false schema': false,
  'null': {'type': 'null'},
  'multiple types': {
    'type': ['string', 'object'],
  },
  'map': {
    'type': 'object',
    'additionalProperties': {'type': 'string'},
  },
  'referenced binary': {r'$ref': '#/components/schemas/Binary'},
  'aliased binary': {r'$ref': '#/components/schemas/BinaryAlias'},
  'referenced map': {r'$ref': '#/components/schemas/Map'},
  'referenced composition': {r'$ref': '#/components/schemas/Composed'},
  'annotated composition': {
    r'$ref': '#/components/schemas/Composed',
    'description': 'Upload',
    'nullable': true,
  },
  'allOf': {
    'allOf': [
      {'type': 'string'},
    ],
  },
  'oneOf': {
    'oneOf': [
      {'type': 'string'},
      {'type': 'object'},
    ],
  },
  'anyOf': {
    'anyOf': [
      {'type': 'string'},
      {'type': 'object'},
    ],
  },
  'array': {
    'type': 'array',
    'items': {'type': 'string'},
  },
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
