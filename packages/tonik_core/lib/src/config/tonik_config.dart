import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/src/config/deprecated_config.dart';
import 'package:tonik_core/src/config/enum_config.dart';
import 'package:tonik_core/src/config/filter_config.dart';
import 'package:tonik_core/src/config/name_overrides_config.dart';
import 'package:tonik_core/src/config/schema_content_type.dart';
import 'package:tonik_core/src/config/transport_config.dart';
import 'package:tonik_core/src/model/content_type.dart';

/// Main configuration for Tonik code generation.
@immutable
class const TonikConfig({
  final NameOverridesConfig nameOverrides = const NameOverridesConfig(),
  final Map<String, ContentType> contentTypes = const {},
  final Map<String, SchemaContentType> contentMediaTypes = const {},
  final FilterConfig filter = const FilterConfig(),
  final DeprecatedConfig deprecated = const DeprecatedConfig(),
  final EnumConfig enums = const EnumConfig(),
  final TransportConfig transport = const TransportConfig(),

  /// When `true`, generated code uses `IList<T>` and `IMap<String, V>` from
  /// `package:fast_immutable_collections` instead of `List<T>` and
  /// `Map<String, V>` for public-facing model types.
  final bool useImmutableCollections = false,

  /// Worker isolates for parallel model file generation. `0` = auto, `1` =
  /// serial, `>= 2` = explicit count.
  final int workerCount = 0,
}) {
  this : assert(workerCount >= 0, 'workerCount must be non-negative');

  @override
  String toString() =>
      'TonikConfig{nameOverrides: $nameOverrides, contentTypes: $contentTypes, '
      'contentMediaTypes: $contentMediaTypes, filter: $filter, '
      'deprecated: $deprecated, enums: $enums, transport: $transport, '
      'useImmutableCollections: $useImmutableCollections, '
      'workerCount: $workerCount}';

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
            enums == other.enums &&
            transport == other.transport &&
            useImmutableCollections == other.useImmutableCollections &&
            workerCount == other.workerCount;
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
      transport,
      useImmutableCollections,
      workerCount,
    );
  }
}
