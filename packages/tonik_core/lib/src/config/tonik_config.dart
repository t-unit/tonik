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
  required final NameOverridesConfig nameOverrides,
  required final Map<String, ContentTypeMapping> contentTypes,
  required final Map<String, SchemaContentType> contentMediaTypes,
  required final FilterConfig filter,
  required final DeprecatedConfig deprecated,
  required final EnumConfig enums,
  required final TransportConfig transport,

  /// When `true`, generated code uses `IList<T>` and `IMap<String, V>` from
  /// `package:fast_immutable_collections` instead of `List<T>` and
  /// `Map<String, V>` for public-facing model types.
  required final bool useImmutableCollections,

  /// Worker isolates for parallel model file generation. `0` = auto, `1` =
  /// serial, `>= 2` = explicit count.
  required final int workerCount,
}) {
  this : assert(workerCount >= 0, 'workerCount must be non-negative');

  static const defaults = TonikConfig(
    nameOverrides: NameOverridesConfig(
      schemas: {},
      properties: {},
      operations: {},
      parameters: {},
      enums: {},
      tags: {},
    ),
    contentTypes: {},
    contentMediaTypes: {},
    filter: FilterConfig(
      includeTags: [],
      excludeTags: [],
      excludeOperations: [],
      excludeSchemas: [],
    ),
    deprecated: DeprecatedConfig(
      operations: DeprecatedHandling.annotate,
      schemas: DeprecatedHandling.annotate,
      parameters: DeprecatedHandling.annotate,
      properties: DeprecatedHandling.annotate,
    ),
    enums: EnumConfig(generateUnknownCase: false, unknownCaseName: 'unknown'),
    transport: TransportConfig(backend: TransportBackend.dio),
    useImmutableCollections: false,
    workerCount: 0,
  );

  @override
  String toString() =>
      'TonikConfig{nameOverrides: $nameOverrides, contentTypes: $contentTypes, '
      'contentMediaTypes: $contentMediaTypes, filter: $filter, '
      'deprecated: $deprecated, enums: $enums, transport: $transport, '
      'useImmutableCollections: $useImmutableCollections, '
      'workerCount: $workerCount}';

  @override
  bool operator ==(Object other) {
    const contentTypeEquality = MapEquality<String, ContentTypeMapping>();
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
    const contentTypeEquality = MapEquality<String, ContentTypeMapping>();
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
