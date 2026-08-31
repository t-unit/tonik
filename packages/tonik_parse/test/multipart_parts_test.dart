import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test(
    'multipart parsing preserves property order and metadata',
    () {
      for (final version in ['3.0.3', '3.1.0']) {
        final api = Importer().import(_document(version));
        final content = api.requestBodies.single.resolvedContent.single;
        expect(content.contentType, ContentType.multipart);
        final parts = _properties(content);
        expect(parts.map((part) => part.name), [
          'serverId',
          'name',
          'file',
          'tags',
          'metadata',
          'attributes',
        ]);
        final models = parts.map((part) => part.model).toList();
        expect(models[0], isA<StringModel>());
        expect(models[1], isA<StringModel>());
        expect(models[2], isA<BinaryModel>());
        expect(models[3], isA<ListModel>());
        expect(models[4], isA<ClassModel>());
        expect(models[5], isA<MapModel>());
        expect(parts[0].isReadOnly, isTrue);
        expect(parts[1].isRequired, isTrue);
        expect(parts[1].isDeprecated, isTrue);
        expect(parts[1].defaultValue, 'guest');
        expect(parts[1].description, 'Public label');
        expect(parts[3].isRequired, isFalse);
        expect(parts[3].isNullable, isTrue);
      }
    },
  );

  test(
    'multipart parsing resolves effective part encodings before generation',
    () {
      for (final version in ['3.0.3', '3.1.0']) {
        final content = Importer()
            .import(_document(version))
            .requestBodies
            .single
            .resolvedContent
            .single;
        final parts = _properties(content);
        final encodings = parts.skip(1).map((part) => part.encoding).toList();
        expect(encodings[0].wireContentType, 'text/plain; charset=latin1');
        expect(encodings[0].textEncoding, TextEncoding.latin1);
        expect(encodings[1].wireContentType, 'application/octet-stream');
        expect(encodings[3].wireContentType, 'application/json');
        expect(encodings[4].wireContentType, 'text/plain');
        expect(encodings[0].headers!.keys, ['X-Label']);
      }
    },
  );

  test('multipart parsing warns for unmatched encoding entries', () {
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);
    addTearDown(subscription.cancel);
    Importer().import(_document('3.1.0'));
    expect(
      records.where((record) => record.level == Level.WARNING),
      hasLength(1),
    );
  });

  test('read-only recursive parts do not warn about their encoding', () {
    final document = _document('3.1.0');
    final components = document['components'] as Map<String, dynamic>;
    components['schemas'] = {
      'Values': {
        'type': 'array',
        'items': {r'$ref': '#/components/schemas/Values'},
      },
    };
    final bodies = components['requestBodies'] as Map<String, dynamic>;
    final body = bodies['Upload'] as Map<String, dynamic>;
    final content = body['content'] as Map<String, dynamic>;
    final mediaType = content['multipart/form-data'] as Map<String, dynamic>;
    final schema = mediaType['schema'] as Map<String, dynamic>;
    final properties = schema['properties'] as Map<String, dynamic>;
    properties['serverId'] = {
      r'$ref': '#/components/schemas/Values',
      'readOnly': true,
    };
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);
    addTearDown(subscription.cancel);
    Importer().import(document);
    expect(
      records.where((record) => record.level == Level.WARNING),
      hasLength(1),
    );
    expect(
      records.singleWhere((record) => record.level == Level.WARNING).message,
      'Encoding key "missing" does not match any property '
      'on the multipart schema. Ignoring.',
    );
  });

  test('multipart aliases resolve to the same request content', () {
    final document = _document('3.1.0');
    final components = document['components'] as Map<String, dynamic>;
    final bodies = components['requestBodies'] as Map<String, dynamic>;
    bodies['UploadAlias'] = {r'$ref': '#/components/requestBodies/Upload'};
    bodies['UploadDoubleAlias'] = {
      r'$ref': '#/components/requestBodies/UploadAlias',
    };
    final api = Importer().import(document);
    final original = api.requestBodies.singleWhere(
      (body) => body.name == 'Upload',
    );
    for (final aliasName in ['UploadAlias', 'UploadDoubleAlias']) {
      final alias = api.requestBodies.singleWhere(
        (body) => body.name == aliasName,
      );
      expect(alias.resolvedContent, original.resolvedContent);
    }
  });

  test('multipart configuration preserves part identity and overrides', () {
    final document = _document('3.1.0');
    final components = document['components'] as Map<String, dynamic>;
    final bodies = components['requestBodies'] as Map<String, dynamic>;
    final body = bodies['Upload'] as Map<String, dynamic>;
    final contentMap = body['content'] as Map<String, dynamic>;
    final mediaType = contentMap['multipart/form-data'] as Map<String, dynamic>;
    components['schemas'] = {'Upload': mediaType['schema']};
    mediaType['schema'] = {r'$ref': '#/components/schemas/Upload'};
    final api = Importer().import(document);
    final content = api.requestBodies.single.resolvedContent.single;
    final originalParts = _properties(content);
    final originalModels = originalParts.map((part) => part.model).toList();
    final transformed = const ConfigTransformer().apply(
      api,
      const TonikConfig(
        nameOverrides: NameOverridesConfig(
          schemas: {'Upload': 'UploadValue'},
          properties: {'Upload.name': 'label'},
        ),
      ),
    );
    final transformedContent =
        transformed.requestBodies.single.resolvedContent.single;
    final transformedParts = _properties(transformedContent);
    expect(transformedParts, hasLength(originalParts.length));
    expect(
      transformedParts.map((part) => part.model),
      originalModels,
    );
    expect(transformedParts[1].nameOverride, 'label');
  });

  test('multipart configuration filters deprecated parts', () {
    final api = Importer().import(_document('3.1.0'));
    final transformed = const ConfigTransformer().apply(
      api,
      const TonikConfig(
        deprecated: DeprecatedConfig(properties: DeprecatedHandling.exclude),
      ),
    );
    expect(
      _properties(
        transformed.requestBodies.single.resolvedContent.single,
      ).map((part) => part.name),
      ['serverId', 'file', 'tags', 'metadata', 'attributes'],
    );
  });

  test('multipart aliases preserve source metadata and independent models', () {
    final document = _document('3.1.0');
    final components = document['components'] as Map<String, dynamic>;
    final bodies = components['requestBodies'] as Map<String, dynamic>;
    final body = bodies['Upload'] as Map<String, dynamic>;
    final contentMap = body['content'] as Map<String, dynamic>;
    final mediaType = contentMap['multipart/form-data'] as Map<String, dynamic>;
    final schema = mediaType['schema'] as Map<String, dynamic>;
    schema['examples'] = [
      {'name': 'schema label'},
    ];
    schema['additionalProperties'] = {
      'type': 'object',
      'properties': {
        'code': {'type': 'integer'},
      },
    };
    components['schemas'] = {
      'Upload': schema,
      'UploadAlias': {r'$ref': '#/components/schemas/Upload'},
    };
    mediaType['schema'] = {
      r'$ref': '#/components/schemas/UploadAlias',
      'nullable': true,
      'description': 'Nullable upload',
    };
    mediaType['example'] = {'name': 'media label'};
    final api = Importer().import(document);
    final content =
        api.requestBodies.single.resolvedContent.single
            as MultipartRequestContent;
    final source = api.models.whereType<ClassModel>().singleWhere(
      (model) => model.name == 'Upload',
    );
    expect(content.name, isNull);
    expect(content.sourceName, 'Upload');
    expect(content.alias!.targetName, 'UploadAlias');
    expect(content.alias!.isNullable, isTrue);
    expect(content.alias!.description, 'Nullable upload');
    expect(content.isNullable, isFalse);
    expect(content.isEffectivelyNullable, isTrue);
    expect(
      content.parts.map((part) => part.model),
      source.properties.map((property) => property.model),
    );
    expect(
      content.additionalPropertiesPolicy,
      same(source.additionalPropertiesPolicy),
    );
    expect(content.schemaExamples.single, source.examples.single);
    expect(content.examples.single, isNot(content.schemaExamples.single));
  });

  test(
    'multipart part normalization preserves metadata and encoding identity',
    () {
      final document = _document('3.1.0');
      final components = document['components'] as Map<String, dynamic>;
      components['schemas'] = {
        'Value': {'type': 'string'},
        'Wrapper': {
          'allOf': [
            {r'$ref': '#/components/schemas/Value'},
          ],
        },
      };
      final bodies = components['requestBodies'] as Map<String, dynamic>;
      final body = bodies['Upload'] as Map<String, dynamic>;
      final contentMap = body['content'] as Map<String, dynamic>;
      final mediaType =
          contentMap['multipart/form-data'] as Map<String, dynamic>;
      final schema = mediaType['schema'] as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      properties['name'] = {
        r'$ref': '#/components/schemas/Wrapper',
        'default': 'hello',
      };
      final api = Importer().import(document);
      final content =
          api.requestBodies.single.resolvedContent.single
              as MultipartRequestContent;
      final part = content.parts[1];
      final encoding = part.encoding;
      const AllOfNormalizer().apply(api);
      expect(content.parts[1], same(part));
      expect(part.encoding, same(encoding));
      expect(part.model.resolved, isA<StringModel>());
      expect(part.effectiveDefaultValue, 'hello');
      expect(part.isRequired, isTrue);
    },
  );
}

List<MultipartPart> _properties(RequestContent content) =>
    (content as MultipartRequestContent).parts;

Map<String, dynamic> _document(String version) => {
  'openapi': version,
  'info': {'title': 'Multipart upload', 'version': '1.0.0'},
  'paths': <String, dynamic>{},
  'components': <String, dynamic>{
    'requestBodies': {
      'Upload': {
        'required': true,
        'content': {
          'multipart/form-data': {
            'schema': {
              'type': 'object',
              'required': ['name', 'file'],
              'properties': {
                'serverId': {'type': 'string', 'readOnly': true},
                'name': {
                  'type': 'string',
                  'description': 'Public label',
                  'deprecated': true,
                  'default': 'guest',
                },
                'file': {'type': 'string', 'format': 'binary'},
                'tags': {
                  'type': version.startsWith('3.0')
                      ? 'array'
                      : ['array', 'null'],
                  if (version.startsWith('3.0')) 'nullable': true,
                  'items': {'type': 'string'},
                },
                'metadata': {
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'integer'},
                  },
                },
                'attributes': {
                  'type': 'object',
                  'additionalProperties': {'type': 'string'},
                },
              },
            },
            'encoding': {
              'name': {
                'contentType': 'text/plain; charset=latin1',
                'headers': {
                  'X-Label': {
                    'schema': {'type': 'string'},
                  },
                },
              },
              'missing': {'contentType': 'text/plain'},
            },
          },
        },
      },
    },
  },
};
