import 'package:tonik_core/tonik_core.dart';

typedef MultipartPartFixture = ({Property property, PartEncoding encoding});

MultipartRequestContent multipartContentFixture(
  Context context,
  List<MultipartPartFixture> parts, {
  String name = 'MultipartBody',
}) => MultipartRequestContent(
  model: ClassModel(
    name: name,
    context: context,
    properties: [for (final part in parts) part.property],
    isDeprecated: false,
    examples: const [],
  ),
  encoding: {for (final part in parts) part.property.name: part.encoding},
  rawContentType: 'multipart/form-data',
  examples: const [],
);

MultipartPartFixture multipartPartFixture({
  required String name,
  required Model model,
  bool isRequired = true,
  bool isNullable = false,
  bool isReadOnly = false,
  bool isWriteOnly = false,
  Object? defaultValue,
  PartEncoding? encoding,
}) => (
  property: Property(
    name: name,
    model: model,
    isRequired: isRequired,
    isNullable: isNullable,
    isDeprecated: false,
    isReadOnly: isReadOnly,
    isWriteOnly: isWriteOnly,
    examples: const [],
    defaultValue: defaultValue,
  ),
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
