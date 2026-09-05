import 'package:tonik_core/tonik_core.dart';

/// The object facts shared by schema and multipart value declarations.
class ObjectDeclaration._({
  required final String name,
  required final List<Property> properties,
  required final AdditionalPropertiesPolicy additionalPropertiesPolicy,
  required final List<Example> examples,
  required final String? description,
  required final bool isDeprecated,
  required final bool isNullable,
  required final bool isReadOnly,
  required final bool isWriteOnly,
}) {
  new fromModel(ClassModel model, String name)
    : this._(
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

  new fromMultipart(MultipartRequestContent content, String name)
    : this._(
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
}
