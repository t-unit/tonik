import 'package:tonik_core/tonik_core.dart';

MultipartRequestContent multipartContentFixture(
  Context context,
  List<MultipartPartFixture> parts, {
  String name = 'MultipartBody',
}) => MultipartRequestContent(
  model: ClassModel(
    name: name,
    context: context,
    isDeprecated: false,
    examples: const [],
    properties: [for (final part in parts) part.property],
  ),
  encoding: {
    for (final part in parts)
      if (part.hasExplicitEncoding) part.property.name: part.encoding,
  },
  rawContentType: 'multipart/form-data',
  examples: const [],
);

final class MultipartPartFixture {
  MultipartPartFixture({
    required String name,
    required Model model,
    required bool isRequired,
    required bool isNullable,
    required bool isDeprecated,
    required List<Example> examples,
    required Object? defaultValue,
    required this.encoding,
    bool isReadOnly = false,
    bool isWriteOnly = false,
    String? nameOverride,
    String? description,
    this.hasExplicitEncoding = true,
  }) : property = Property(
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
       );

  final Property property;
  final PartEncoding encoding;
  final bool hasExplicitEncoding;
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
        ),
  );
}
