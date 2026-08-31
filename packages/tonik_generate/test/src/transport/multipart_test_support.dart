import 'package:tonik_core/tonik_core.dart';

MultipartRequestContent multipartContentFixture(
  Context context,
  List<Property> properties, {
  Map<Property, PartEncoding>? encodings,
}) => MultipartRequestContent(
  name: 'MultipartBody',
  context: context,
  parts: [
    for (final property in properties)
      multipartPartFixture(property, encoding: encodings?[property]),
  ],
  rawContentType: 'multipart/form-data',
  examples: const [],
);

MultipartRequestContent multipartContentFromModel({
  required ClassModel model,
  required String rawContentType,
  required List<Example> examples,
  Map<Property, PartEncoding>? multipartEncoding,
  String? wireContentType,
  TextEncoding textEncoding = TextEncoding.utf8,
}) => MultipartRequestContent(
  name: model.name,
  nameOverride: model.nameOverride,
  context: model.context,
  description: model.description,
  isDeprecated: model.isDeprecated,
  isNullable: model.isNullable,
  isReadOnly: model.isReadOnly,
  isWriteOnly: model.isWriteOnly,
  additionalPropertiesPolicy: model.additionalPropertiesPolicy,
  schemaExamples: model.examples,
  parts: [
    for (final property in model.properties)
      multipartPartFixture(property, encoding: multipartEncoding?[property]),
  ],
  rawContentType: rawContentType,
  wireContentType: wireContentType,
  textEncoding: textEncoding,
  examples: examples,
);

MultipartPart multipartPartFixture(
  Property property, {
  PartEncoding? encoding,
}) => MultipartPart(
  name: property.name,
  nameOverride: property.nameOverride,
  description: property.description,
  model: property.model,
  isRequired: property.isRequired,
  isNullable: property.isNullable,
  isDeprecated: property.isDeprecated,
  isReadOnly: property.isReadOnly,
  isWriteOnly: property.isWriteOnly,
  examples: property.examples,
  defaultValue: property.defaultValue,
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
