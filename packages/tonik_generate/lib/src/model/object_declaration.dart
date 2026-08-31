import 'package:tonik_core/tonik_core.dart';

/// The object facts shared by schema and multipart value declarations.
class ObjectDeclaration {
  const ObjectDeclaration({
    required this.name,
    required this.properties,
    required this.additionalPropertiesPolicy,
    required this.examples,
    required this.description,
    required this.isDeprecated,
    required this.isNullable,
    required this.isReadOnly,
    required this.isWriteOnly,
  });

  ObjectDeclaration.fromModel(ClassModel model, String name)
    : this(
        name: name,
        properties: model.properties,
        additionalPropertiesPolicy: model.additionalPropertiesPolicy,
        examples: model.examples,
        description: model.description,
        isDeprecated: model.isDeprecated,
        isNullable: model.isNullable,
        isReadOnly: model.isReadOnly,
        isWriteOnly: model.isWriteOnly,
      );

  ObjectDeclaration.fromMultipart(MultipartRequestContent content, String name)
    : this(
        name: name,
        properties: [
          for (final part in content.parts)
            Property(
              name: part.name,
              nameOverride: part.nameOverride,
              description: part.description,
              model: part.model,
              isRequired: part.isRequired,
              isNullable: part.isNullable,
              isDeprecated: part.isDeprecated,
              isReadOnly: part.isReadOnly,
              isWriteOnly: part.isWriteOnly,
              defaultValue: part.defaultValue,
              examples: part.examples,
            ),
        ],
        additionalPropertiesPolicy: content.additionalPropertiesPolicy,
        examples: content.schemaExamples,
        description: content.description,
        isDeprecated: content.isDeprecated,
        isNullable: content.isNullable,
        isReadOnly: content.isReadOnly,
        isWriteOnly: content.isWriteOnly,
      );

  final String name;
  final List<Property> properties;
  final AdditionalPropertiesPolicy additionalPropertiesPolicy;
  final List<Example> examples;
  final String? description;
  final bool isDeprecated;
  final bool isNullable;
  final bool isReadOnly;
  final bool isWriteOnly;
}
