import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik/src/config/log_level.dart';
import 'package:tonik_core/tonik_core.dart';

/// CLI-specific configuration that wraps [TonikConfig] with CLI-only options.
///
/// This class extends the core [TonikConfig] with CLI-specific settings
/// like [logLevel] that don't belong in the core package.
@immutable
class CliConfig {
  const CliConfig({
    this.spec,
    this.outputDir,
    this.packageName,
    this.logLevel,
    this.nameOverrides = const NameOverridesConfig(),
    this.contentTypes = const {},
    this.contentMediaTypes = const {},
    this.filter = const FilterConfig(),
    this.deprecated = const DeprecatedConfig(),
    this.enums = const EnumConfig(),
    this.useImmutableCollections = false,
  });

  /// Path to the OpenAPI specification file.
  final String? spec;

  /// Output directory for generated code.
  final String? outputDir;

  /// Name of the generated package.
  final String? packageName;

  final LogLevel? logLevel;

  final NameOverridesConfig nameOverrides;

  /// Custom content type mappings: `contentType -> serializationFormat`.
  final Map<String, ContentType> contentTypes;

  /// Schema-level contentMediaType mappings for encoded content.
  final Map<String, SchemaContentType> contentMediaTypes;

  final FilterConfig filter;

  final DeprecatedConfig deprecated;

  final EnumConfig enums;

  /// When `true`, generated code uses `IList<T>` and `IMap<String, V>` from
  /// `package:fast_immutable_collections` instead of `List<T>` and
  /// `Map<String, V>` for public-facing model types.
  final bool useImmutableCollections;

  TonikConfig toTonikConfig() => TonikConfig(
    nameOverrides: nameOverrides,
    contentTypes: contentTypes,
    contentMediaTypes: contentMediaTypes,
    filter: filter,
    deprecated: deprecated,
    enums: enums,
    useImmutableCollections: useImmutableCollections,
  );

  static const _contentTypeEquality = MapEquality<String, ContentType>();
  static const _schemaContentTypeEquality =
      MapEquality<String, SchemaContentType>();

  @override
  String toString() =>
      'CliConfig{spec: $spec, outputDir: $outputDir, '
      'packageName: $packageName, logLevel: $logLevel, '
      'nameOverrides: $nameOverrides, contentTypes: $contentTypes, '
      'contentMediaTypes: $contentMediaTypes, filter: $filter, '
      'deprecated: $deprecated, enums: $enums, '
      'useImmutableCollections: $useImmutableCollections}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CliConfig &&
          runtimeType == other.runtimeType &&
          spec == other.spec &&
          outputDir == other.outputDir &&
          packageName == other.packageName &&
          logLevel == other.logLevel &&
          nameOverrides == other.nameOverrides &&
          _contentTypeEquality.equals(contentTypes, other.contentTypes) &&
          _schemaContentTypeEquality.equals(
            contentMediaTypes,
            other.contentMediaTypes,
          ) &&
          filter == other.filter &&
          deprecated == other.deprecated &&
          enums == other.enums &&
          useImmutableCollections == other.useImmutableCollections;

  @override
  int get hashCode => Object.hash(
    spec,
    outputDir,
    packageName,
    logLevel,
    nameOverrides,
    _contentTypeEquality.hash(contentTypes),
    _schemaContentTypeEquality.hash(contentMediaTypes),
    filter,
    deprecated,
    enums,
    useImmutableCollections,
  );
}
