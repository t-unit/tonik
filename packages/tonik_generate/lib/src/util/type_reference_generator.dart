import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

const _ficUrl =
    'package:fast_immutable_collections/fast_immutable_collections.dart';

/// Generates a TypeReference from a model.
TypeReference typeReference(
  Model model,
  NameManager nameManager,
  String package, {
  bool isNullableOverride = false,
  bool useImmutableCollections = false,
}) {
  return switch (model) {
    // Named ListModels are emitted as typedefs at the top level — references
    // to them must use the typedef name (handled by the NamedModel branch
    // below), not the underlying List<...> expansion. The expansion happens
    // exactly once in TypedefGenerator.generateListTypedef.
    final ListModel m when model.name == null => TypeReference(
      (b) => b
        ..symbol = useImmutableCollections ? 'IList' : 'List'
        ..url = useImmutableCollections ? _ficUrl : 'dart:core'
        ..types.add(
          typeReference(
            m.content,
            nameManager,
            package,
            isNullableOverride: m.isContentNullable,
            useImmutableCollections: useImmutableCollections,
          ),
        )
        ..isNullable = isNullableOverride || m.isNullable,
    ),
    final MapModel m when model.name == null => TypeReference(
      (b) => b
        ..symbol = useImmutableCollections ? 'IMap' : 'Map'
        ..url = useImmutableCollections ? _ficUrl : 'dart:core'
        ..types.addAll([
          refer('String', 'dart:core'),
          typeReference(
            m.valueModel,
            nameManager,
            package,
            isNullableOverride: m.isValueNullable,
            useImmutableCollections: useImmutableCollections,
          ),
        ])
        ..isNullable = isNullableOverride || m.isNullable,
    ),
    final AliasModel m when m.name == null => typeReference(
      m.model,
      nameManager,
      package,
      isNullableOverride: m.isNullable || isNullableOverride,
      useImmutableCollections: useImmutableCollections,
    ),
    final NamedModel m => TypeReference(
      (b) => b
        ..symbol = nameManager.modelName(m)
        ..url = sourceFileUrl(
          package,
          'model',
          nameManager.modelName(m),
          nameManager,
        )
        ..isNullable = isNullableOverride || ((m is EnumModel) && m.isNullable),
    ),
    StringModel _ => TypeReference(
      (b) => b
        ..symbol = 'String'
        ..url = 'dart:core'
        ..isNullable = isNullableOverride,
    ),
    IntegerModel _ => TypeReference(
      (b) => b
        ..symbol = 'int'
        ..url = 'dart:core'
        ..isNullable = isNullableOverride,
    ),
    DoubleModel _ => TypeReference(
      (b) => b
        ..symbol = 'double'
        ..url = 'dart:core'
        ..isNullable = isNullableOverride,
    ),
    NumberModel _ => TypeReference(
      (b) => b
        ..symbol = 'num'
        ..url = 'dart:core'
        ..isNullable = isNullableOverride,
    ),
    BooleanModel _ => TypeReference(
      (b) => b
        ..symbol = 'bool'
        ..url = 'dart:core'
        ..isNullable = isNullableOverride,
    ),
    DateTimeModel _ => TypeReference(
      (b) => b
        ..symbol = 'DateTime'
        ..url = 'dart:core'
        ..isNullable = isNullableOverride,
    ),
    DateModel _ => TypeReference(
      (b) => b
        ..symbol = 'Date'
        ..url = 'package:tonik_util/tonik_util.dart'
        ..isNullable = isNullableOverride,
    ),
    DecimalModel _ => TypeReference(
      (b) => b
        ..symbol = 'BigDecimal'
        ..url = 'package:big_decimal/big_decimal.dart'
        ..isNullable = isNullableOverride,
    ),
    UriModel _ => TypeReference(
      (b) => b
        ..symbol = 'Uri'
        ..url = 'dart:core'
        ..isNullable = isNullableOverride,
    ),
    BinaryModel _ || Base64Model _ => TypeReference(
      (b) => b
        ..symbol = 'TonikFile'
        ..url = 'package:tonik_util/tonik_util.dart'
        ..isNullable = isNullableOverride,
    ),
    final NeverModel m => TypeReference(
      (b) => b
        ..symbol = 'Never'
        ..url = 'dart:core'
        ..isNullable = isNullableOverride || m.isNullable,
    ),
    AnyModel _ => TypeReference(
      (b) => b
        ..symbol = 'Object'
        ..url = 'dart:core'
        ..isNullable = true,
    ),
    final CompositeModel m => TypeReference(
      (b) => b
        ..symbol = nameManager.modelName(m)
        ..url = sourceFileUrl(
          package,
          'model',
          nameManager.modelName(m),
          nameManager,
        )
        ..isNullable = isNullableOverride,
    ),
  };
}

/// Returns a TypeReference for [Map<String, Object?>].
///
/// This can be used with Code.scope to create properly
/// qualified type references in generated code.
TypeReference buildMapStringObjectType() => TypeReference(
  (b) => b
    ..symbol = 'Map'
    ..url = 'dart:core'
    ..types.addAll([
      TypeReference(
        (b) => b
          ..symbol = 'String'
          ..url = 'dart:core',
      ),
      TypeReference(
        (b) => b
          ..symbol = 'Object?'
          ..url = 'dart:core',
      ),
    ]),
);

/// Returns a TypeReference for `Map<String, PropertyValue>`.
TypeReference buildMapStringPropertyValueType() => TypeReference(
  (b) => b
    ..symbol = 'Map'
    ..url = 'dart:core'
    ..types.addAll([
      refer('String', 'dart:core'),
      refer('PropertyValue', 'package:tonik_util/tonik_util.dart'),
    ]),
);

TypeReference buildParameterEntryListType() => TypeReference(
  (b) => b
    ..symbol = 'List'
    ..url = 'dart:core'
    ..types.add(
      refer('ParameterEntry', 'package:tonik_util/tonik_util.dart'),
    ),
);

/// Returns a Parameter for a boolean named parameter with default value.
Parameter buildBoolParameter(
  String name, {
  bool defaultValue = false,
  bool required = false,
}) => Parameter(
  (b) => b
    ..name = name
    ..type = refer('bool', 'dart:core')
    ..named = true
    ..required = required
    ..defaultTo = required ? null : literalBool(defaultValue).code,
);

/// Returns a Parameter for a String named parameter with default value.
Parameter buildStringParameter(
  String name, {
  String? defaultValue,
  bool required = false,
}) => Parameter(
  (b) => b
    ..name = name
    ..type = refer('String', 'dart:core')
    ..named = true
    ..required = required
    ..defaultTo = required || defaultValue == null
        ? null
        : specLiteralString(defaultValue).code,
);

/// Returns a list of common encoding parameters (explode and allowEmpty).
List<Parameter> buildEncodingParameters() => [
  buildBoolParameter('explode', required: true),
  buildBoolParameter('allowEmpty', required: true),
];

/// Encoding parameters for simple-style `toSimple`, which additionally accepts
/// [literal] so header field-values are transmitted without URI encoding.
List<Parameter> buildSimpleEncodingParameters() => [
  ...buildEncodingParameters(),
  buildBoolParameter('literal'),
];

/// A `Map<String, FormFieldEncoding> fieldEncodings = const {}` parameter that
/// carries per-property reserved-character overrides into form encoding.
Parameter buildFieldEncodingsParameter() => Parameter(
  (b) => b
    ..name = 'fieldEncodings'
    ..type = TypeReference(
      (t) => t
        ..symbol = 'Map'
        ..url = 'dart:core'
        ..types.addAll([
          refer('String', 'dart:core'),
          refer('FormFieldEncoding', 'package:tonik_util/tonik_util.dart'),
        ]),
    )
    ..named = true
    ..defaultTo = literalConstMap({}).code,
);

/// Encoding parameters for form-style `toForm`.
List<Parameter> buildFormEncodingParameters() => [
  ...buildEncodingParameters(),
  buildBoolParameter('useQueryComponent'),
  buildBoolParameter('allowReserved'),
  buildFieldEncodingsParameter(),
];

/// Shared parameters for every composite `parameterProperties` method.
List<Parameter> buildParameterPropertiesParameters() => [
  buildBoolParameter('allowEmpty', defaultValue: true),
];

/// Encoding parameters for `toDeepObject`, kept separate from
/// [buildEncodingParameters] so matrix/label/simple never carry allowReserved.
List<Parameter> buildDeepObjectEncodingParameters() => [
  ...buildEncodingParameters(),
  buildBoolParameter('allowReserved'),
];

/// Parameters for an inline `uriEncode` signature.
List<Parameter> buildUriEncodeParameters() => [
  buildBoolParameter('allowEmpty', required: true),
  buildBoolParameter('useQueryComponent'),
  buildBoolParameter('allowReserved'),
];

/// Returns a `<String, PropertyValue>{}` literal.
LiteralMapExpression buildEmptyMapStringPropertyValue() => literalMap(
  {},
  TypeReference(
    (b) => b
      ..symbol = 'String'
      ..url = 'dart:core',
  ),
  TypeReference(
    (b) => b
      ..symbol = 'PropertyValue'
      ..url = 'package:tonik_util/tonik_util.dart',
  ),
);

/// Returns a LiteralMapExpression for an empty [Map<String, Object?>] literal.
LiteralMapExpression buildEmptyMapStringObject() => literalMap(
  {},
  TypeReference(
    (b) => b
      ..symbol = 'String'
      ..url = 'dart:core',
  ),
  TypeReference(
    (b) => b
      ..symbol = 'Object?'
      ..url = 'dart:core',
  ),
);
