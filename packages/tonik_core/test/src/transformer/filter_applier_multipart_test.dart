import 'package:test/test.dart';
import 'package:tonik_core/src/transformer/filter_applier.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  test('excluding a real schema keeps a colliding request projection', () {
    final context = Context.initial();
    final source = MapModel(
      valueModel: StringModel(context: context.push('Foo').push('value')),
      context: context.push('Foo'),
      examples: const [],
      name: 'Foo',
      nameOverride: null,
      isNullable: false,
      isValueNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final projection = MapModel(
      valueModel: BinaryModel(
        context: context.push('Foo').push('multipart').push('value'),
      ),
      context: context.push('Foo').push('multipart'),
      examples: const [],
      name: 'FooMultipart',
      nameOverride: null,
      isNullable: false,
      isValueNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final realSchema = MapModel(
      valueModel: StringModel(
        context: context.push('FooMultipart').push('value'),
      ),
      context: context.push('FooMultipart'),
      examples: const [],
      name: 'FooMultipart',
      nameOverride: null,
      isNullable: false,
      isValueNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final multipart = MultipartRequestContent(
      model: source,
      requestModel: projection,
      requestSources: const {},
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

    final filtered = const FilterApplier().filterSchemas(
      models: {source, projection, realSchema},
      requestBodies: {body},
      excludeSchemas: ['FooMultipart'],
    );

    expect(filtered, contains(source));
    expect(filtered, contains(projection));
    expect(filtered, isNot(contains(realSchema)));
    expect(multipart.requestModel, same(projection));
  });
}
