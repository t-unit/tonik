import 'package:test/test.dart';
import 'package:tonik_core/src/transformer/name_override_applier.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  test('projected schema and property names follow their shared sources', () {
    final context = Context.initial();
    final sourceProperty = Property(
      name: 'payload',
      model: StringModel(context: context.push('payload')),
      isRequired: true,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
      isReadOnly: false,
      isWriteOnly: false,
      nameOverride: null,
      description: null,
    );
    final projectedProperty = Property(
      name: 'payload',
      model: BinaryModel(context: context.push('multipart').push('payload')),
      isRequired: true,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
      isReadOnly: false,
      isWriteOnly: false,
      nameOverride: null,
      description: null,
    );
    final sourceClass = ClassModel(
      properties: [sourceProperty],
      context: context.push('Payload'),
      isDeprecated: false,
      examples: const [],
      name: 'Payload',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final projectedClass = ClassModel(
      properties: [projectedProperty],
      context: context.push('Payload').push('multipart'),
      isDeprecated: false,
      examples: const [],
      name: 'PayloadMultipart',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final sourceAllOf = AllOfModel(
      models: [sourceClass],
      context: context.push('Upload'),
      isDeprecated: false,
      examples: const [],
      name: 'Upload',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );
    final projectedAllOf = AllOfModel(
      models: [projectedClass],
      context: context.push('Upload').push('multipart'),
      isDeprecated: false,
      examples: const [],
      name: 'UploadMultipart',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );
    final sourceAlias = AliasModel(
      model: sourceAllOf,
      context: context.push('UploadAlias'),
      examples: const [],
      defaultValue: null,
      name: 'UploadAlias',
      nameOverride: null,
      description: null,
      isDeprecated: false,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final projectedAlias = AliasModel(
      model: projectedAllOf,
      context: context.push('UploadAlias').push('multipart'),
      examples: const [],
      defaultValue: null,
      name: 'UploadAliasMultipart',
      nameOverride: null,
      description: null,
      isDeprecated: false,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final multipart = MultipartRequestContent(
      model: sourceAlias,
      requestModel: projectedAlias,
      requestSources: {projectedProperty: sourceProperty},
      encoding: const {},
      rawContentType: 'multipart/form-data',
      examples: const [],
      wireContentType: null,
      textEncoding: TextEncoding.utf8,
    );
    final body = RequestBodyObject(
      name: 'UploadBody',
      context: context.push('UploadBody'),
      description: null,
      isRequired: true,
      content: {multipart},
    );
    final models = <Model>{
      sourceClass,
      sourceAllOf,
      sourceAlias,
      projectedClass,
      projectedAllOf,
      projectedAlias,
    };

    NameOverrideApplier()
      ..applySchemaOverrides(
        models,
        {
          'Payload': 'RenamedPayload',
          'Upload': 'RenamedUpload',
          'UploadAlias': 'RenamedAlias',
        },
        requestBodies: {body},
      )
      ..applyPropertyOverrides(
        models,
        {'Payload.payload': 'data'},
        requestBodies: {body},
      );

    expect(sourceClass.nameOverride, 'RenamedPayload');
    expect(projectedClass.nameOverride, 'RenamedPayloadMultipart');
    expect(sourceAllOf.nameOverride, 'RenamedUpload');
    expect(projectedAllOf.nameOverride, 'RenamedUploadMultipart');
    expect(sourceAlias.nameOverride, 'RenamedAlias');
    expect(projectedAlias.nameOverride, 'RenamedAliasMultipart');
    expect(sourceProperty.nameOverride, 'data');
    expect(projectedProperty.nameOverride, 'data');
    expect(projectedProperty.name, 'payload');
  });

  test('synthetic projection keys only rename real source schemas', () {
    final context = Context.initial();
    final sourcePayload = Property(
      name: 'payload',
      model: StringModel(context: context.push('payload')),
      isRequired: true,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
      isReadOnly: false,
      isWriteOnly: false,
      nameOverride: null,
      description: null,
    );
    final projectedPayload = Property(
      name: 'payload',
      model: BinaryModel(context: context.push('multipart').push('payload')),
      isRequired: true,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
      isReadOnly: false,
      isWriteOnly: false,
      nameOverride: null,
      description: null,
    );
    final sharedNote = Property(
      name: 'note',
      model: StringModel(context: context.push('note')),
      isRequired: false,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
      isReadOnly: false,
      isWriteOnly: false,
      nameOverride: null,
      description: null,
    );
    final realNote = Property(
      name: 'note',
      model: StringModel(context: context.push('real').push('note')),
      isRequired: false,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
      isReadOnly: false,
      isWriteOnly: false,
      nameOverride: null,
      description: null,
    );
    final source = ClassModel(
      properties: [sourcePayload, sharedNote],
      context: context.push('Foo'),
      isDeprecated: false,
      examples: const [],
      name: 'Foo',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final projection = ClassModel(
      properties: [projectedPayload, sharedNote],
      context: context.push('Foo').push('multipart'),
      isDeprecated: false,
      examples: const [],
      name: 'FooMultipart',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final realSchema = ClassModel(
      properties: [realNote],
      context: context.push('FooMultipart'),
      isDeprecated: false,
      examples: const [],
      name: 'FooMultipart',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final body = RequestBodyObject(
      name: 'Upload',
      context: context.push('Upload'),
      description: null,
      isRequired: true,
      content: {
        MultipartRequestContent(
          model: source,
          requestModel: projection,
          requestSources: {
            projectedPayload: sourcePayload,
            sharedNote: sharedNote,
          },
          encoding: const {},
          rawContentType: 'multipart/form-data',
          examples: const [],
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        ),
      },
    );
    final models = <Model>{source, projection, realSchema};
    final applier = NameOverrideApplier()
      ..applySchemaOverrides(
        models,
        {'FooMultipart': 'RealUpload'},
        requestBodies: {body},
      )
      ..applyPropertyOverrides(
        models,
        {'FooMultipart.note': 'realLabel'},
        requestBodies: {body},
      );

    expect(source.nameOverride, isNull);
    expect(projection.nameOverride, isNull);
    expect(sharedNote.nameOverride, isNull);
    expect(realSchema.nameOverride, 'RealUpload');
    expect(realNote.nameOverride, 'realLabel');

    applier
      ..applySchemaOverrides(
        models,
        {'Foo': 'RenamedFoo'},
        requestBodies: {body},
      )
      ..applyPropertyOverrides(
        models,
        {'Foo.note': 'label'},
        requestBodies: {body},
      );

    expect(source.nameOverride, 'RenamedFoo');
    expect(projection.nameOverride, 'RenamedFooMultipart');
    expect(sharedNote.nameOverride, 'label');
    expect(realSchema.nameOverride, 'RealUpload');
    expect(realNote.nameOverride, 'realLabel');
  });

  test('source overrides reach multipart input after schema filtering', () {
    final context = Context.initial();
    final sourceProperty = Property(
      name: 'payload',
      model: StringModel(context: context.push('Foo').push('payload')),
      isRequired: true,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
      isReadOnly: false,
      isWriteOnly: false,
      nameOverride: null,
      description: null,
    );
    final projectedProperty = Property(
      name: 'payload',
      model: BinaryModel(context: context.push('FooMultipart').push('payload')),
      isRequired: true,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
      isReadOnly: false,
      isWriteOnly: false,
      nameOverride: null,
      description: null,
    );
    final source = ClassModel(
      properties: [sourceProperty],
      context: context.push('Foo'),
      isDeprecated: false,
      examples: const [],
      name: 'Foo',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final projection = ClassModel(
      properties: [projectedProperty],
      context: context.push('Foo').push('multipart'),
      isDeprecated: false,
      examples: const [],
      name: 'FooMultipart',
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final multipart = MultipartRequestContent(
      model: source,
      requestModel: projection,
      requestSources: {projectedProperty: sourceProperty},
      encoding: const {},
      rawContentType: 'multipart/form-data',
      examples: const [],
      wireContentType: null,
      textEncoding: TextEncoding.utf8,
    );
    final body = RequestBodyObject(
      name: 'Upload',
      context: context.push('Upload'),
      description: null,
      isRequired: true,
      content: {multipart},
    );
    final document = ApiDocument(
      title: 'Test API',
      version: '1.0.0',
      models: {source, projection},
      responseHeaders: const {},
      requestHeaders: const {},
      servers: const {},
      operations: const {},
      responses: const {},
      queryParameters: const {},
      pathParameters: const {},
      cookieParameters: const {},
      requestBodies: {body},
      summary: null,
      description: null,
      contact: null,
      license: null,
      termsOfService: null,
      externalDocs: null,
    );
    const config = TonikConfig(
      nameOverrides: NameOverridesConfig(
        schemas: {'Foo': 'RenamedFoo'},
        properties: {'Foo.payload': 'data'},
        operations: {},
        parameters: {},
        enums: {},
        tags: {},
      ),
      contentTypes: {},
      contentMediaTypes: {},
      filter: FilterConfig(
        includeTags: [],
        excludeTags: [],
        excludeOperations: [],
        excludeSchemas: ['Foo'],
      ),
      deprecated: DeprecatedConfig(
        operations: DeprecatedHandling.annotate,
        schemas: DeprecatedHandling.annotate,
        parameters: DeprecatedHandling.annotate,
        properties: DeprecatedHandling.annotate,
      ),
      enums: EnumConfig(generateUnknownCase: false, unknownCaseName: 'unknown'),
      transport: TransportConfig(backend: TransportBackend.dio),
      useImmutableCollections: false,
      workerCount: 0,
    );

    final transformed = const ConfigTransformer().apply(document, config);

    expect(transformed.models, isNot(contains(source)));
    expect(transformed.models, contains(projection));
    expect(projection.nameOverride, 'RenamedFooMultipart');
    expect(projectedProperty.nameOverride, 'data');
    expect(projectedProperty.name, 'payload');
    expect(multipart.requestModel, same(projection));
  });
}
