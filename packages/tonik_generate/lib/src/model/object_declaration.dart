import 'package:tonik_core/tonik_core.dart';

/// The object facts shared by schema and multipart value declarations.
class ObjectDeclaration {
  ObjectDeclaration.fromModel(ClassModel model, this.name)
    : properties = model.properties,
      additionalPropertiesPolicy = model.additionalPropertiesPolicy,
      examples = model.examples,
      description = model.description,
      isDeprecated = model.isDeprecated,
      isNullable = model.isNullable,
      isReadOnly = model.isReadOnly,
      isWriteOnly = model.isWriteOnly;

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
