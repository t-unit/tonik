import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/model/components.dart';
import 'package:tonik_parse/src/model/info.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model_importer.dart';

void main() {
  group('Binary format parsing', () {
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
        schemas: {},
        responses: {},
        parameters: {},
        requestBodies: {},
        headers: {},
        securitySchemes: {},
        pathItems: {},
        examples: null,
      ),
      tags: [],
    );

    final inlineBinary = Schema(
      ref: null,
      type: ['string'],
      format: 'binary',
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
      defs: null,
      contentEncoding: null,
      contentMediaType: null,
      contentSchema: null,
      rawDefault: null,
    );

    final inlineByte = Schema(
      ref: null,
      type: ['string'],
      format: 'byte',
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
      defs: null,
      contentEncoding: null,
      contentMediaType: null,
      contentSchema: null,
      rawDefault: null,
    );

    final inlineContentEncodingBase64 = Schema(
      ref: null,
      type: ['string'],
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
      defs: null,
      contentEncoding: 'base64',
      contentMediaType: null,
      contentSchema: null,
      rawDefault: null,
    );

    late ModelImporter importer;

    setUp(() {
      importer = ModelImporter(
        openApiObject,
        exampleImporter: ExampleImporter(openApiObject: openApiObject),
      )..import();
    });

    test('returns BinaryModel for format: binary', () {
      final context = Context.initial().pushAll(['components', 'schemas']);

      final result = importer.importSchema(inlineBinary, context);

      expect(result, isA<BinaryModel>());
      expect(result.context.path, ['components', 'schemas']);
    });

    test('returns Base64Model for format: byte', () {
      final context = Context.initial().pushAll(['components', 'schemas']);

      final result = importer.importSchema(inlineByte, context);

      expect(result, isA<Base64Model>());
      expect(result.context.path, ['components', 'schemas']);
    });

    test(
      'returns Base64Model for contentEncoding: base64 without config',
      () {
        final context = Context.initial().pushAll(['components', 'schemas']);

        final result = importer.importSchema(
          inlineContentEncodingBase64,
          context,
        );

        expect(result, isA<Base64Model>());
        expect(result.context.path, ['components', 'schemas']);
      },
    );

    test('does not add inline binary schema to models', () {
      final context = Context.initial().pushAll(['components', 'schemas']);

      final result = importer.importSchema(inlineBinary, context);
      expect(importer.models.contains(result), isFalse);
    });

    test('does not add inline byte schema to models', () {
      final context = Context.initial().pushAll(['components', 'schemas']);

      final result = importer.importSchema(inlineByte, context);
      expect(importer.models.contains(result), isFalse);
    });

    test('does not add inline contentEncoding:base64 schema to models', () {
      final context = Context.initial().pushAll(['components', 'schemas']);

      final result = importer.importSchema(
        inlineContentEncodingBase64,
        context,
      );
      expect(importer.models.contains(result), isFalse);
    });
  });

  group('Named binary schema', () {
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
          'FileData': Schema(
            ref: null,
            type: ['string'],
            format: 'binary',
            required: [],
            enumerated: null,
            allOf: null,
            anyOf: null,
            oneOf: null,
            not: null,
            items: null,
            properties: {},
            description: 'Binary file data',
            isNullable: false,
            discriminator: null,
            isDeprecated: false,
            uniqueItems: false,
            xDartName: null,
            xDartEnum: null,
            defs: null,
            contentEncoding: null,
            contentMediaType: null,
            contentSchema: null,
            rawDefault: null,
          ),
          'Base64Data': Schema(
            ref: null,
            type: ['string'],
            format: 'byte',
            required: [],
            enumerated: null,
            allOf: null,
            anyOf: null,
            oneOf: null,
            not: null,
            items: null,
            properties: {},
            description: 'Base64 encoded string',
            isNullable: false,
            discriminator: null,
            isDeprecated: false,
            uniqueItems: false,
            xDartName: null,
            xDartEnum: null,
            defs: null,
            contentEncoding: null,
            contentMediaType: null,
            contentSchema: null,
            rawDefault: null,
          ),
          'EncodedData': Schema(
            ref: null,
            type: ['string'],
            format: null,
            required: [],
            enumerated: null,
            allOf: null,
            anyOf: null,
            oneOf: null,
            not: null,
            items: null,
            properties: {},
            description: 'Base64 encoded binary data',
            isNullable: false,
            discriminator: null,
            isDeprecated: false,
            uniqueItems: false,
            xDartName: null,
            xDartEnum: null,
            defs: null,
            contentEncoding: 'base64',
            contentMediaType: null,
            contentSchema: null,
            rawDefault: null,
          ),
        },
        responses: {},
        parameters: {},
        requestBodies: {},
        headers: {},
        securitySchemes: {},
        pathItems: {},
        examples: null,
      ),
      tags: [],
    );

    late ModelImporter importer;

    setUp(() {
      importer = ModelImporter(
        openApiObject,
        exampleImporter: ExampleImporter(openApiObject: openApiObject),
      )..import();
    });

    test('creates AliasModel wrapping BinaryModel for named binary schema', () {
      final fileData = importer.models.firstWhere(
        (m) => m is NamedModel && m.name == 'FileData',
      );

      expect(fileData, isA<AliasModel>());
      expect((fileData as AliasModel).model, isA<BinaryModel>());
    });

    test('creates AliasModel wrapping Base64Model for named byte schema', () {
      final base64Data = importer.models.firstWhere(
        (m) => m is NamedModel && m.name == 'Base64Data',
      );

      expect(base64Data, isA<AliasModel>());
      expect((base64Data as AliasModel).model, isA<Base64Model>());
    });

    test(
      'creates AliasModel wrapping Base64Model for named '
      'contentEncoding: base64 schema',
      () {
        final encodedData = importer.models.firstWhere(
          (m) => m is NamedModel && m.name == 'EncodedData',
        );

        expect(encodedData, isA<AliasModel>());
        expect((encodedData as AliasModel).model, isA<Base64Model>());
      },
    );
  });

  group('contentMediaType parsing', () {
    final openApiObject = OpenApiObject(
      openapi: '3.1.0',
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
        schemas: {},
        responses: {},
        parameters: {},
        requestBodies: {},
        headers: {},
        securitySchemes: {},
        pathItems: {},
        examples: null,
      ),
      tags: [],
    );

    final stringWithEncodingAndMediaType = Schema(
      ref: null,
      type: ['string'],
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
      defs: null,
      contentEncoding: 'base64',
      contentMediaType: 'image/png',
      contentSchema: null,
      rawDefault: null,
    );

    final stringWithEncodingNoMediaType = Schema(
      ref: null,
      type: ['string'],
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
      defs: null,
      contentEncoding: 'base64',
      contentMediaType: null,
      contentSchema: null,
      rawDefault: null,
    );

    final stringWithBinaryFormatAndBase64Encoding = Schema(
      ref: null,
      type: ['string'],
      format: 'binary',
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
      defs: null,
      contentEncoding: 'base64',
      contentMediaType: null,
      contentSchema: null,
      rawDefault: null,
    );

    test(
      'returns Base64Model for contentEncoding: base64 with unconfigured '
      'contentMediaType',
      () {
        final importer = ModelImporter(
          openApiObject,
          exampleImporter: ExampleImporter(openApiObject: openApiObject),
        )..import();
        final context = Context.initial().pushAll(['components', 'schemas']);

        final result = importer.importSchema(
          stringWithEncodingAndMediaType,
          context,
        );

        expect(result, isA<Base64Model>());
      },
    );

    test('returns Base64Model for contentEncoding: base64 without '
        'contentMediaType', () {
      final importer = ModelImporter(
        openApiObject,
        exampleImporter: ExampleImporter(openApiObject: openApiObject),
      )..import();
      final context = Context.initial().pushAll(['components', 'schemas']);

      final result = importer.importSchema(
        stringWithEncodingNoMediaType,
        context,
      );

      expect(result, isA<Base64Model>());
    });

    test('contentEncoding: base64 overrides format: binary', () {
      final importer = ModelImporter(
        openApiObject,
        exampleImporter: ExampleImporter(openApiObject: openApiObject),
      )..import();
      final context = Context.initial().pushAll(['components', 'schemas']);

      final result = importer.importSchema(
        stringWithBinaryFormatAndBase64Encoding,
        context,
      );

      expect(result, isA<Base64Model>());
    });

    test('returns Base64Model for contentEncoding: base64 when config maps '
        'contentMediaType to binary', () {
      final importer = ModelImporter(
        openApiObject,
        contentMediaTypes: {
          'image/png': SchemaContentType.binary,
        },
        exampleImporter: ExampleImporter(openApiObject: openApiObject),
      )..import();

      final context = Context.initial().pushAll(['components', 'schemas']);
      final result = importer.importSchema(
        stringWithEncodingAndMediaType,
        context,
      );

      expect(result, isA<Base64Model>());
    });

    test('returns Base64Model for uppercase contentEncoding value', () {
      final stringWithUppercaseEncoding = Schema(
        ref: null,
        type: ['string'],
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
        defs: null,
        contentEncoding: 'BASE64',
        contentMediaType: null,
        contentSchema: null,
        rawDefault: null,
      );

      final importer = ModelImporter(
        openApiObject,
        exampleImporter: ExampleImporter(openApiObject: openApiObject),
      )..import();
      final context = Context.initial().pushAll(['components', 'schemas']);

      final result = importer.importSchema(
        stringWithUppercaseEncoding,
        context,
      );

      expect(result, isA<Base64Model>());
    });

    test('returns BinaryModel for unsupported contentEncoding', () {
      final stringWithUnsupportedEncoding = Schema(
        ref: null,
        type: ['string'],
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
        defs: null,
        contentEncoding: 'quoted-printable',
        contentMediaType: null,
        contentSchema: null,
        rawDefault: null,
      );

      final importer = ModelImporter(
        openApiObject,
        exampleImporter: ExampleImporter(openApiObject: openApiObject),
      )..import();
      final context = Context.initial().pushAll(['components', 'schemas']);

      final result = importer.importSchema(
        stringWithUnsupportedEncoding,
        context,
      );

      expect(result, isA<BinaryModel>());
    });

    test('returns StringModel when config maps contentMediaType to text', () {
      final stringWithTextMediaType = Schema(
        ref: null,
        type: ['string'],
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
        defs: null,
        contentEncoding: 'base64',
        contentMediaType: 'text/plain',
        contentSchema: null,
        rawDefault: null,
      );

      final importer = ModelImporter(
        openApiObject,
        contentMediaTypes: {
          'text/plain': SchemaContentType.text,
        },
        exampleImporter: ExampleImporter(openApiObject: openApiObject),
      )..import();

      final context = Context.initial().pushAll(['components', 'schemas']);
      final result = importer.importSchema(stringWithTextMediaType, context);

      expect(result, isA<StringModel>());
    });

    test('config can override any media type to text', () {
      final importer = ModelImporter(
        openApiObject,
        contentMediaTypes: {
          'image/png': SchemaContentType.text,
        },
        exampleImporter: ExampleImporter(openApiObject: openApiObject),
      )..import();

      final context = Context.initial().pushAll(['components', 'schemas']);
      final result = importer.importSchema(
        stringWithEncodingAndMediaType,
        context,
      );

      expect(result, isA<StringModel>());
    });
  });
}
