import 'package:tonik_core/tonik_core.dart';

MultipartRequestContent multipartContentFixture(
  Context context,
  List<MultipartPartFixture> parts, {
  String name = 'MultipartBody',
}) {
  final model = ClassModel(
    name: name,
    context: context,
    isDeprecated: false,
    examples: const [],
    properties: [for (final part in parts) part.property],
    nameOverride: null,
    description: null,
    additionalPropertiesPolicy: null,
    isNullable: false,
    isReadOnly: false,
    isWriteOnly: false,
  );
  return multipartRequestContentFixture(
    model: model,
    encoding: {
      for (final part in parts)
        if (part.hasExplicitEncoding) part.property.name: part.encoding,
    },
    rawContentType: 'multipart/form-data',
    examples: const [],
    wireContentType: null,
    textEncoding: TextEncoding.utf8,
  );
}

MultipartRequestContent multipartRequestContentFixture({
  required Model model,
  required Map<String, PartEncoding> encoding,
  required String rawContentType,
  required List<Example> examples,
  required String? wireContentType,
  required TextEncoding textEncoding,
}) => MultipartRequestContent(
  model: model,
  encoding: encoding,
  rawContentType: rawContentType,
  examples: examples,
  wireContentType: wireContentType,
  textEncoding: textEncoding,
);

final class MultipartPartFixture._({
  required final Property property,
  required final PartEncoding encoding,
  required final bool hasExplicitEncoding,
}) {
  new({
    required String name,
    required Model model,
    required bool isRequired,
    required bool isNullable,
    required bool isDeprecated,
    required List<Example> examples,
    required Object? defaultValue,
    required PartEncoding encoding,
    bool isReadOnly = false,
    bool isWriteOnly = false,
    String? nameOverride,
    String? description,
    bool hasExplicitEncoding = true,
  }) : this._(
         property: Property(
           name: name,
           nameOverride: nameOverride,
           description: description,
           model: model,
           isRequired: isRequired,
           isNullable: isNullable,
           isDeprecated: isDeprecated,
           isReadOnly: isReadOnly,
           isWriteOnly: isWriteOnly,
           examples: examples,
           defaultValue: defaultValue,
         ),
         encoding: encoding,
         hasExplicitEncoding: hasExplicitEncoding,
       );
}

MultipartPartFixture multipartPartFixture({
  required String name,
  required Model model,
  bool isRequired = true,
  bool isNullable = false,
  bool isReadOnly = false,
  bool isWriteOnly = false,
  Object? defaultValue,
  PartEncoding? encoding,
}) {
  return MultipartPartFixture(
    name: name,
    model: model,
    isRequired: isRequired,
    isNullable: isNullable,
    isDeprecated: false,
    isReadOnly: isReadOnly,
    isWriteOnly: isWriteOnly,
    examples: const [],
    defaultValue: defaultValue,
    hasExplicitEncoding: encoding != null,
    encoding:
        encoding ??
        const PartEncoding(
          contentType: null,
          rawContentType: null,
          headers: null,
          style: null,
          explode: null,
          allowReserved: null,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        ),
  );
}
