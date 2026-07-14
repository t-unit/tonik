import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';

/// Names owned by generated response classes that headers must not claim.
const responseHeaderReservedNameReplacements = {'body': 'bodyHeader'};

/// Normalizes and sorts properties from a response object.
/// Returns a list of normalized properties with their original names.
List<({String normalizedName, Property property, ResponseHeader? header})>
normalizeResponseProperties(ResponseObject response) {
  final headerMap = <Property, ResponseHeader>{};

  final headerProperties = response.headers.entries.map((header) {
    final resolvedHeader = header.value.resolve(name: header.key);
    final property = Property(
      name: header.key,
      model: resolvedHeader.model,
      isRequired: resolvedHeader.isRequired,
      isNullable: false,
      isDeprecated: resolvedHeader.isDeprecated,
      examples: const [],
      defaultValue: null,
    );

    headerMap[property] = header.value;
    return property;
  }).toList();

  final normalizedProperties = [
    ...normalizeProperties(
      headerProperties,
      reservedNameReplacements: responseHeaderReservedNameReplacements,
    ),
    if (response.bodies.length == 1)
      ...normalizeProperties([
        Property(
          name: 'body',
          model: response.bodies.first.model,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ]),
  ];

  final sorted = [...normalizedProperties]
    ..sort((a, b) {
      // Required fields come before non-required fields
      if (a.property.isRequired != b.property.isRequired) {
        return a.property.isRequired ? -1 : 1;
      }
      // Keep original order for fields with same required status
      return normalizedProperties.indexOf(a) - normalizedProperties.indexOf(b);
    });

  return sorted.map((norm) {
    return (
      normalizedName: norm.normalizedName,
      property: norm.property,
      header: headerMap[norm.property],
    );
  }).toList();
}
