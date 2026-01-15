import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/src/config/deprecated_config.dart';
import 'package:tonik_core/src/config/enum_config.dart';
import 'package:tonik_core/src/config/filter_config.dart';
import 'package:tonik_core/src/config/name_overrides_config.dart';
import 'package:tonik_core/src/config/schema_content_type.dart';
import 'package:tonik_core/src/model/content_type.dart';

/// Main configuration for Tonik code generation.
@immutable
class TonikConfig {
  const TonikConfig({
    this.nameOverrides = const NameOverridesConfig(),
    this.contentTypes = const {},
    this.contentMediaTypes = const {},
    this.filter = const FilterConfig(),
    this.deprecated = const DeprecatedConfig(),
    this.enums = const EnumConfig(),
  });

  final NameOverridesConfig nameOverrides;
  final Map<String, ContentType> contentTypes;
  final Map<String, SchemaContentType> contentMediaTypes;

  final FilterConfig filter;

  final DeprecatedConfig deprecated;

  final EnumConfig enums;

  @override
  String toString() =>
      'TonikConfig{nameOverrides: $nameOverrides, contentTypes: $contentTypes, '
      'contentMediaTypes: $contentMediaTypes, filter: $filter, '
      'deprecated: $deprecated, enums: $enums}';

  @override
  bool operator ==(Object other) {
    const contentTypeEquality = MapEquality<String, ContentType>();
    const schemaContentTypeEquality = MapEquality<String, SchemaContentType>();
    return identical(this, other) ||
        other is TonikConfig &&
            runtimeType == other.runtimeType &&
            nameOverrides == other.nameOverrides &&
            contentTypeEquality.equals(contentTypes, other.contentTypes) &&
            schemaContentTypeEquality.equals(
              contentMediaTypes,
              other.contentMediaTypes,
            ) &&
            filter == other.filter &&
            deprecated == other.deprecated &&
            enums == other.enums;
  }

  @override
  int get hashCode {
    const contentTypeEquality = MapEquality<String, ContentType>();
    const schemaContentTypeEquality = MapEquality<String, SchemaContentType>();
    return Object.hash(
      nameOverrides,
      contentTypeEquality.hash(contentTypes),
      schemaContentTypeEquality.hash(contentMediaTypes),
      filter,
      deprecated,
      enums,
    );
  }
}
