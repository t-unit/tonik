import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  final context = Context.initial();

  Property field(String name, Model model) => Property(
    name: name,
    nameOverride: null,
    description: null,
    model: model,
    isRequired: true,
    isNullable: false,
    isDeprecated: false,
    isReadOnly: false,
    isWriteOnly: false,
    examples: const [],
    defaultValue: null,
  );

  ClassModel object(String name, List<Property> properties) => ClassModel(
    name: name,
    properties: properties,
    context: context.push(name),
    isDeprecated: false,
    examples: const [],
    nameOverride: null,
    description: null,
    additionalPropertiesPolicy: null,
    isNullable: false,
    isReadOnly: false,
    isWriteOnly: false,
  );

  MultipartRequestContent content(Model model) => MultipartRequestContent(
    model: model,
    encoding: const {},
    rawContentType: 'multipart/form-data',
    examples: const [],
    wireContentType: null,
    textEncoding: TextEncoding.utf8,
  );

  test('keeps sources and effective content types on named parts', () {
    final label = field('label', StringModel(context: context));
    final file = field('file', BinaryModel(context: context));
    final body = content(object('Upload', [label, file]));

    expect(body.layout.runtimeEncodingError, isNull);
    expect(body.layout.fields.map((part) => part.wireName), ['label', 'file']);
    expect(body.layout.fields.first.sources.single.property, same(label));
    expect(body.layout.fields.first.encoding.contentType, ContentType.text);
    expect(body.layout.fields.first.encoding.wireContentType, 'text/plain');
    expect(body.layout.fields.last.sources.single.property, same(file));
    expect(body.layout.fields.last.encoding.contentType, ContentType.bytes);
    expect(
      body.layout.fields.last.encoding.wireContentType,
      'application/octet-stream',
    );
    expect(body.layout.fields.first.encoding.rawContentType, 'text/plain');
  });

  test('allOf model replacement swaps the complete layout', () {
    final first = object('First', [
      field('old', StringModel(context: context)),
    ]);
    final second = object('Second', [
      field('new', BinaryModel(context: context)),
    ]);
    final body = content(first);
    final firstLayout = body.layout;

    expect(body.model, same(first));
    expect(body.layout.fields.single.wireName, 'old');

    body.normalizeAllOf((_) => second);

    expect(body.model, same(second));
    expect(body.layout, isNot(same(firstLayout)));
    expect(firstLayout.fields.single.wireName, 'old');
    expect(body.layout.fields.single.wireName, 'new');
    expect(body.layout.fields.single.encoding.contentType, ContentType.bytes);
  });

  test('resolves sources when allOf normalization replaces the root', () {
    final property = field('label', StringModel(context: context));
    final member = object('Member', [property]);
    final root = AllOfModel(
      name: 'Wrapped',
      models: [
        AnyModel(context: context),
        member,
      ],
      context: context,
      description: null,
      isDeprecated: false,
      examples: const [],
      nameOverride: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );
    const encoding = {
      'label': PartEncoding(
        contentType: ContentType.json,
        rawContentType: 'application/json',
        wireContentType: 'application/json',
        textEncoding: TextEncoding.utf8,
        headers: null,
        style: null,
        explode: null,
        allowReserved: null,
      ),
    };
    final body = MultipartRequestContent(
      model: root,
      encoding: encoding,
      rawContentType: 'multipart/form-data',
      examples: const [],
      wireContentType: null,
      textEncoding: TextEncoding.utf8,
    );
    expect(body.layout.runtimeEncodingError, isNotNull);
    final requestBody = RequestBodyObject(
      name: 'Request',
      context: context,
      description: null,
      isRequired: true,
      content: {body},
    );
    final document = ApiDocument(
      title: 'Test',
      version: '1',
      summary: null,
      description: null,
      contact: null,
      license: null,
      termsOfService: null,
      externalDocs: null,
      models: {root, member},
      responseHeaders: const {},
      requestHeaders: const {},
      servers: const {},
      operations: const {},
      responses: const {},
      queryParameters: const {},
      pathParameters: const {},
      cookieParameters: const {},
      requestBodies: {requestBody},
    );

    const AllOfNormalizer(normalizeSingleMembers: true).apply(document);

    expect(body.model, isA<AliasModel>());
    expect(body.model, same(body.layout.model));
    expect(body.layout.fields.single.sources.single.members, isEmpty);
    expect(body.layout.fields.single.sources.single.property, same(property));
    expect(body.layout.fields.single.encoding.contentType, ContentType.json);
  });

  test('retains repeated source identities and merge policy', () {
    final leftField = field('tag', StringModel(context: context));
    final rightField = field('tag', StringModel(context: context));
    final left = object('Left', [leftField]);
    final right = object('Right', [rightField]);
    final root = AllOfModel(
      name: 'Combined',
      models: [left, right],
      context: context,
      description: null,
      isDeprecated: false,
      examples: const [],
      nameOverride: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );
    final body = content(root);
    final layout = body.layout;
    final part = layout.fields.single;

    expect(part.sources, hasLength(2));
    expect(part.sources.first.members.single.model, same(left));
    expect(part.sources.first.members.single.index, 0);
    expect(part.sources.last.members.single.model, same(right));
    expect(part.sources.last.members.single.index, 1);
    expect(part.sources.first.property, same(leftField));
    expect(part.sources.last.property, same(rightField));
    expect(part.mergePolicy, MultipartMergePolicy.dynamicValues);
    expect(layout.fields.clear, throwsUnsupportedError);
    expect(part.sources.clear, throwsUnsupportedError);
    expect(part.sources.first.members.clear, throwsUnsupportedError);

    left.properties = const [];
    body.refreshLayoutAfterPropertyExclusion();

    expect(body.layout.fields.single.sources, hasLength(1));
    expect(body.layout.fields.single.sources.single.property, same(rightField));
    expect(body.layout.fields.single.mergePolicy, MultipartMergePolicy.single);
  });

  test('keeps named part order when a repeated source is excluded', () {
    final deprecatedTag = field('tag', StringModel(context: context));
    final other = field('other', StringModel(context: context));
    final activeTag = field('tag', StringModel(context: context));
    final left = object('Left', [deprecatedTag, other]);
    final right = object('Right', [activeTag]);
    final root = AllOfModel(
      name: 'Combined',
      models: [left, right],
      context: context,
      description: null,
      isDeprecated: false,
      examples: const [],
      nameOverride: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );
    final body = content(root);

    expect(body.layout.fields.map((part) => part.wireName), ['tag', 'other']);
    expect(body.layout.fields.first.sources, hasLength(2));

    left.properties = [other];
    body.refreshLayoutAfterPropertyExclusion();

    expect(body.layout.fields.map((part) => part.wireName), ['tag', 'other']);
    expect(body.layout.fields.first.sources.single.property, same(activeTag));
    expect(body.layout.fields.first.mergePolicy, MultipartMergePolicy.single);
    expect(body.layout.fields.last.sources.single.property, same(other));
  });

  test('excluding a field adds its encoding key to an existing error', () {
    final tagged = field('tag', StringModel(context: context));
    final model = object('Upload', [tagged]);
    const partEncoding = PartEncoding(
      contentType: ContentType.text,
      rawContentType: 'text/plain',
      wireContentType: 'text/plain',
      textEncoding: TextEncoding.utf8,
      headers: null,
      style: null,
      explode: null,
      allowReserved: null,
    );
    final body = MultipartRequestContent(
      model: model,
      encoding: const {'unknown': partEncoding, 'tag': partEncoding},
      rawContentType: 'multipart/form-data',
      examples: const [],
      wireContentType: null,
      textEncoding: TextEncoding.utf8,
    );

    expect(
      body.layout.runtimeEncodingError,
      'Multipart encoding references properties that are not writable or '
      'do not exist in the body model: unknown.',
    );

    model.properties = const [];
    body.refreshLayoutAfterPropertyExclusion();

    expect(body.layout.fields, isEmpty);
    expect(
      body.layout.runtimeEncodingError,
      'Multipart encoding references properties that are not writable or '
      'do not exist in the body model: unknown, tag.',
    );
  });

  test('excluding a field updates additional-property names', () {
    final tagged = field('tag', StringModel(context: context));
    final model = object('Upload', [tagged])
      ..additionalPropertiesPolicy = AllowedAdditionalProperties(
        valueModel: StringModel(context: context),
        origin: AdditionalPropertiesOrigin.explicit,
      );
    final body = content(model);

    expect(body.layout.additionalFields?.declaredWireNames, {'tag'});

    model.properties = const [];
    body.refreshLayoutAfterPropertyExclusion();

    expect(body.layout.fields, isEmpty);
    expect(body.layout.additionalFields?.declaredWireNames, isEmpty);
  });

  test('copies declared encodings before resolving parts', () {
    final model = object('Upload', [
      field('tag', StringModel(context: context)),
    ]);
    final encoding = <String, PartEncoding>{};
    final body = MultipartRequestContent(
      model: model,
      encoding: encoding,
      rawContentType: 'multipart/form-data',
      examples: const [],
      wireContentType: null,
      textEncoding: TextEncoding.utf8,
    );

    encoding['unknown'] = const PartEncoding(
      contentType: ContentType.text,
      rawContentType: 'text/plain',
      wireContentType: null,
      textEncoding: TextEncoding.utf8,
      headers: null,
      style: null,
      explode: null,
      allowReserved: null,
    );

    expect(body.layout.runtimeEncodingError, isNull);
    expect(body.layout.fields.single.wireName, 'tag');
  });

  test('distinguishes two uses of the same allOf member', () {
    final member = object('Shared', [
      field('tag', StringModel(context: context)),
    ]);
    final root = AllOfModel(
      name: 'Combined',
      models: [member, member],
      context: context,
      description: null,
      isDeprecated: false,
      examples: const [],
      nameOverride: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );

    final sources = content(root).layout.fields.single.sources;

    expect(sources, hasLength(2));
    expect(sources.first.members.single.index, 0);
    expect(sources.last.members.single.index, 1);
  });
}
