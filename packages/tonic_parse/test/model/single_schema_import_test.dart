import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/src/model/components.dart';
import 'package:tonic_parse/src/model/info.dart';
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model/reference.dart';
import 'package:tonic_parse/src/model/schema.dart';
import 'package:tonic_parse/src/model_importer.dart';

void main() {
  final openApiObject = OpenApiObject(
    info: Info(
      title: 'Test API',
      description: 'Test API Description',
      version: '1.0.0',
    ),
    servers: [],
    paths: {},
    components: Components(
      schemas: {
        'TestModel': InlinedObject(
          Schema(
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
          ),
        ),
      },
      responses: {},
      parameters: {},
      requestBodies: {},
      headers: {},
    ),
    tags: [],
  );

  final inlinePrimitive = InlinedObject(
    Schema(
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
    ),
  );

  final inlineClass = InlinedObject(
    Schema(
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
    ),
  );

  final reference = Reference<Schema>('#/components/schemas/TestModel');

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
}
