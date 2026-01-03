import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/components.dart';
import 'package:tonik_parse/src/model/info.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model_importer.dart';

void main() {
  final openApiObject = OpenApiObject(
    openapi: '3.0.0',
    info: Info(
      title: 'Test API',
      description: 'Test API Description',
      version: '1.0.0',
      contact: null,
      license: null,
      termsOfService: null,
      summary: null,
    ),
    servers: [],
    paths: {},
    components: Components(
      schemas: {
        'TestModel': Schema(
          ref: null,
          type: ['object'],
          format: null,
          required: [],
          enumerated: null,
          allOf: null,
          anyOf: null,
          oneOf: null,
          not: null,
          items: null,
          properties: {},
          description: '',
          isNullable: false,
          discriminator: null,
          isDeprecated: false,
          uniqueItems: false,
          xDartName: null,
          xDartEnum: null,
        ),
      },
      responses: {},
      parameters: {},
      requestBodies: {},
      headers: {},
      securitySchemes: {},
      pathItems: {},
    ),
    tags: [],
  );

  final inlinePrimitive = Schema(
    ref: null,
    type: ['string'],
    format: 'string',
    required: [],
    enumerated: null,
    allOf: null,
    anyOf: null,
    oneOf: null,
    not: null,
    items: null,
    properties: {},
    description: '',
    isNullable: false,
    discriminator: null,
    isDeprecated: false,
    uniqueItems: false,
    xDartName: null,
    xDartEnum: null,
  );

  final inlineClass = Schema(
    ref: null,
    type: ['object'],
    format: null,
    required: [],
    enumerated: null,
    allOf: null,
    anyOf: null,
    oneOf: null,
    not: null,
    items: null,
    properties: {},
    description: '',
    isNullable: false,
    discriminator: null,
    isDeprecated: false,
    uniqueItems: false,
    xDartName: null,
    xDartEnum: null,
  );

  final inlineUri = Schema(
    ref: null,
    type: ['string'],
    format: 'uri',
    required: [],
    enumerated: null,
    allOf: null,
    anyOf: null,
    oneOf: null,
    not: null,
    items: null,
    properties: {},
    description: '',
    isNullable: false,
    discriminator: null,
    isDeprecated: false,
    uniqueItems: false,
    xDartName: null,
    xDartEnum: null,
  );

  final inlineUrl = Schema(
    ref: null,
    type: ['string'],
    format: 'url',
    required: [],
    enumerated: null,
    allOf: null,
    anyOf: null,
    oneOf: null,
    not: null,
    items: null,
    properties: {},
    description: '',
    isNullable: false,
    discriminator: null,
    isDeprecated: false,
    uniqueItems: false,
    xDartName: null,
    xDartEnum: null,
  );

  final reference = Schema(
    ref: '#/components/schemas/TestModel',
    type: [],
    format: null,
    required: null,
    enumerated: null,
    allOf: null,
    anyOf: null,
    oneOf: null,
    not: null,
    items: null,
    properties: null,
    description: null,
    isNullable: null,
    discriminator: null,
    isDeprecated: null,
    uniqueItems: null,
    xDartName: null,
    xDartEnum: null,
  );

  late ModelImporter importer;

  setUp(() {
    importer = ModelImporter(openApiObject)..import();
  });

  test('returns parsed model', () {
    final context = Context.initial().pushAll(['components', 'schemas']);

    final result = importer.importSchema(inlinePrimitive, context);

    expect(result, isA<StringModel>());
    expect(result.context.path, ['components', 'schemas']);
  });

  test('returns model that is referenced', () {
    final result = importer.importSchema(reference, Context.initial());

    expect(result, isA<ClassModel>());
    expect((result as ClassModel).name, 'TestModel');
  });

  test('adds inline schema to models', () {
    final context = Context.initial().pushAll(['components', 'schemas']);

    final result = importer.importSchema(inlineClass, context);
    expect(importer.models, contains(result));
  });

  test('does not add inline primitive schema to models', () {
    final context = Context.initial().pushAll(['components', 'schemas']);

    final result = importer.importSchema(inlinePrimitive, context);
    expect(importer.models.contains(result), isFalse);
  });

  test('does not add referenced schema to models', () {
    final importer = ModelImporter(openApiObject)..import();
    final models = Set.of(importer.models);

    final _ = importer.importSchema(reference, Context.initial());

    expect(importer.models, models);
  });

  test('returns UriModel for uri format schema', () {
    final context = Context.initial().pushAll(['components', 'schemas']);

    final result = importer.importSchema(inlineUri, context);

    expect(result, isA<UriModel>());
    expect(result.context.path, ['components', 'schemas']);
  });

  test('returns UriModel for url format schema', () {
    final context = Context.initial().pushAll(['components', 'schemas']);

    final result = importer.importSchema(inlineUrl, context);

    expect(result, isA<UriModel>());
    expect(result.context.path, ['components', 'schemas']);
  });

  test('does not add inline uri schema to models', () {
    final context = Context.initial().pushAll(['components', 'schemas']);

    final result = importer.importSchema(inlineUri, context);
    expect(importer.models.contains(result), isFalse);
  });

  test('does not add inline url schema to models', () {
    final context = Context.initial().pushAll(['components', 'schemas']);

    final result = importer.importSchema(inlineUrl, context);
    expect(importer.models.contains(result), isFalse);
  });
}
