import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/src/config/deprecated_config.dart';
import 'package:tonik_core/src/config/enum_config.dart';
import 'package:tonik_core/src/config/filter_config.dart';
import 'package:tonik_core/src/config/name_overrides_config.dart';
import 'package:tonik_core/src/model/content_type.dart';

/// Main configuration for Tonik code generation.
@immutable
class TonikConfig {
  const TonikConfig({
    this.nameOverrides = const NameOverridesConfig(),
    this.contentTypes = const {},
    this.filter = const FilterConfig(),
    this.deprecated = const DeprecatedConfig(),
    this.enums = const EnumConfig(),
  });

  // CLI-only fields removed. See CliConfig in tonik for CLI options.

  final NameOverridesConfig nameOverrides;

  /// Custom content type mappings: `contentType -> serializationFormat`.
  final Map<String, ContentType> contentTypes;

  final FilterConfig filter;

  final DeprecatedConfig deprecated;

  final EnumConfig enums;

  static const _mapEquality = MapEquality<String, ContentType>();

  @override
  String toString() =>
      'TonikConfig{nameOverrides: $nameOverrides, contentTypes: $contentTypes, '
      'filter: $filter, deprecated: $deprecated, enums: $enums}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TonikConfig &&
          runtimeType == other.runtimeType &&
          nameOverrides == other.nameOverrides &&
          _mapEquality.equals(contentTypes, other.contentTypes) &&
          filter == other.filter &&
          deprecated == other.deprecated &&
          enums == other.enums;

  @override
  int get hashCode => Object.hash(
    nameOverrides,
    _mapEquality.hash(contentTypes),
    filter,
    deprecated,
    enums,
  );
}
