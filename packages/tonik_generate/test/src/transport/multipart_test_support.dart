import 'package:tonik_core/tonik_core.dart';

MultipartRequestContent multipartContentFixture(
  Context context,
  List<MultipartPart> parts, {
  String name = 'MultipartBody',
}) => MultipartRequestContent(
  name: name,
  context: context,
  parts: parts,
  rawContentType: 'multipart/form-data',
  examples: const [],
);

MultipartPart multipartPartFixture({
  required String name,
  required Model model,
  bool isRequired = true,
  bool isNullable = false,
  bool isReadOnly = false,
  bool isWriteOnly = false,
  Object? defaultValue,
  PartEncoding? encoding,
}) => MultipartPart(
  name: name,
  model: model,
  isRequired: isRequired,
  isNullable: isNullable,
  isDeprecated: false,
  isReadOnly: isReadOnly,
  isWriteOnly: isWriteOnly,
  examples: const [],
  defaultValue: defaultValue,
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
