import 'dart:io';

import 'package:tonik/src/config/log_level.dart';
import 'package:tonik/src/config/tonik_config.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:yaml/yaml.dart';

/// Extension for loading and merging CLI configuration.
extension ConfigLoader on CliConfig {
  /// Loads config from file path. Returns default config if file doesn't exist.
  static CliConfig load(String? configPath) {
    if (configPath == null) {
      return const CliConfig();
    }

    final file = File(configPath);
    if (!file.existsSync()) {
      return const CliConfig();
    }

    final content = file.readAsStringSync();
    if (content.trim().isEmpty) {
      return const CliConfig();
    }

    final dynamic yaml;
    try {
      yaml = loadYaml(content);
    } on YamlException catch (e) {
      throw ConfigLoaderException('Failed to parse config file: ${e.message}');
    }

    if (yaml == null) {
      return const CliConfig();
    }

    if (yaml is! YamlMap) {
      throw ConfigLoaderException('Config file must be a map');
    }

    return _parseConfig(yaml);
  }

  static CliConfig _parseConfig(YamlMap yaml) {
    return CliConfig(
      spec: yaml['spec'] as String?,
      outputDir: yaml['outputDir'] as String?,
      packageName: yaml['packageName'] as String?,
      logLevel: _parseLogLevel(yaml['logLevel']),
      nameOverrides: _parseNameOverrides(yaml['nameOverrides']),
      contentTypes: _parseContentTypes(yaml['contentTypes']),
      contentMediaTypes: _parseContentMediaTypes(yaml['contentMediaTypes']),
      filter: _parseFilter(yaml['filter']),
      deprecated: _parseDeprecated(yaml['deprecated']),
      enums: _parseEnums(yaml['enums']),
    );
  }

  static NameOverridesConfig _parseNameOverrides(dynamic value) {
    if (value == null) {
      return const NameOverridesConfig();
    }
    if (value is! YamlMap) {
      throw ConfigLoaderException(
        'Invalid config: "nameOverrides" must be a map',
      );
    }

    return NameOverridesConfig(
      schemas: _parseStringMap(value['schemas'], 'nameOverrides.schemas'),
      properties: _parseStringMap(
        value['properties'],
        'nameOverrides.properties',
      ),
      operations: _parseStringMap(
        value['operations'],
        'nameOverrides.operations',
      ),
      parameters: _parseStringMap(
        value['parameters'],
        'nameOverrides.parameters',
      ),
      enums: _parseStringMap(value['enums'], 'nameOverrides.enums'),
      tags: _parseStringMap(value['tags'], 'nameOverrides.tags'),
    );
  }

  static Map<String, String> _parseStringMap(dynamic value, String fieldName) {
    if (value == null) {
      return const {};
    }
    if (value is! YamlMap) {
      throw ConfigLoaderException('Invalid config: "$fieldName" must be a map');
    }

    return Map.fromEntries(
      value.entries.map(
        (e) => MapEntry(e.key.toString(), e.value?.toString() ?? ''),
      ),
    );
  }

  static Map<String, ContentType> _parseContentTypes(dynamic value) {
    if (value == null) {
      return const {};
    }
    if (value is! YamlMap) {
      throw ConfigLoaderException(
        'Invalid config: "contentTypes" must be a map',
      );
    }

    return Map.fromEntries(
      value.entries.map((e) {
        final key = e.key.toString();
        final contentType = _parseContentType(e.value, key);
        return MapEntry(key, contentType);
      }),
    );
  }

  static ContentType _parseContentType(dynamic value, String key) {
    if (value == null) {
      throw ConfigLoaderException(
        'Invalid config: contentTypes["$key"] cannot be null',
      );
    }

    final stringValue = value.toString();
    return switch (stringValue) {
      'json' => ContentType.json,
      'text' => ContentType.text,
      'bytes' => ContentType.bytes,
      'form' => ContentType.form,
      _ => throw ConfigLoaderException(
        'Invalid content type for "$key": $stringValue. '
        'Must be one of: json, text, bytes, form',
      ),
    };
  }

  static Map<String, SchemaContentType> _parseContentMediaTypes(dynamic value) {
    if (value == null) {
      return const {};
    }
    if (value is! YamlMap) {
      throw ConfigLoaderException(
        'Invalid config: "contentMediaTypes" must be a map',
      );
    }

    return Map.fromEntries(
      value.entries.map((e) {
        final key = e.key.toString();
        final schemaContentType = _parseSchemaContentType(e.value, key);
        return MapEntry(key, schemaContentType);
      }),
    );
  }

  static SchemaContentType _parseSchemaContentType(dynamic value, String key) {
    if (value == null) {
      throw ConfigLoaderException(
        'Invalid config: contentMediaTypes["$key"] cannot be null',
      );
    }

    final stringValue = value.toString();
    return switch (stringValue) {
      'binary' => SchemaContentType.binary,
      'text' => SchemaContentType.text,
      _ => throw ConfigLoaderException(
        'Invalid schema content type for "$key": $stringValue. '
        'Must be one of: binary, text',
      ),
    };
  }

  static FilterConfig _parseFilter(dynamic value) {
    if (value == null) {
      return const FilterConfig();
    }
    if (value is! YamlMap) {
      throw ConfigLoaderException('Invalid config: "filter" must be a map');
    }

    return FilterConfig(
      includeTags: _parseStringList(value['includeTags'], 'filter.includeTags'),
      excludeTags: _parseStringList(value['excludeTags'], 'filter.excludeTags'),
      excludeOperations: _parseStringList(
        value['excludeOperations'],
        'filter.excludeOperations',
      ),
      excludeSchemas: _parseStringList(
        value['excludeSchemas'],
        'filter.excludeSchemas',
      ),
    );
  }

  static List<String> _parseStringList(dynamic value, String fieldName) {
    if (value == null) {
      return const [];
    }
    if (value is! YamlList) {
      throw ConfigLoaderException(
        'Invalid config: "$fieldName" must be a list',
      );
    }

    return value.map((e) => e.toString()).toList();
  }

  static DeprecatedConfig _parseDeprecated(dynamic value) {
    if (value == null) {
      return const DeprecatedConfig();
    }
    if (value is! YamlMap) {
      throw ConfigLoaderException('Invalid config: "deprecated" must be a map');
    }

    return DeprecatedConfig(
      operations: _parseDeprecatedHandling(
        value['operations'],
        DeprecatedHandling.annotate,
      ),
      schemas: _parseDeprecatedHandling(
        value['schemas'],
        DeprecatedHandling.annotate,
      ),
      parameters: _parseDeprecatedHandling(
        value['parameters'],
        DeprecatedHandling.annotate,
      ),
      properties: _parseDeprecatedHandling(
        value['properties'],
        DeprecatedHandling.annotate,
      ),
    );
  }

  static DeprecatedHandling _parseDeprecatedHandling(
    dynamic value,
    DeprecatedHandling defaultValue,
  ) {
    if (value == null) {
      return defaultValue;
    }

    final stringValue = value.toString();
    return switch (stringValue) {
      'annotate' => DeprecatedHandling.annotate,
      'exclude' => DeprecatedHandling.exclude,
      'ignore' => DeprecatedHandling.ignore,
      _ => throw ConfigLoaderException(
        'Invalid deprecated handling value: $stringValue. '
        'Must be one of: annotate, exclude, ignore',
      ),
    };
  }

  static EnumConfig _parseEnums(dynamic value) {
    if (value == null) {
      return const EnumConfig();
    }
    if (value is! YamlMap) {
      throw ConfigLoaderException('Invalid config: "enums" must be a map');
    }

    return EnumConfig(
      generateUnknownCase: value['generateUnknownCase'] as bool? ?? false,
      unknownCaseName: value['unknownCaseName'] as String? ?? 'unknown',
    );
  }

  static LogLevel? _parseLogLevel(dynamic value) {
    if (value == null) {
      return null;
    }

    final stringValue = value.toString();
    return switch (stringValue) {
      'verbose' => LogLevel.verbose,
      'info' => LogLevel.info,
      'warn' => LogLevel.warn,
      'silent' => LogLevel.silent,
      _ => throw ConfigLoaderException(
        'Invalid log level: $stringValue. '
        'Must be one of: verbose, info, warn, silent',
      ),
    };
  }

  /// Merges this config with CLI arguments. CLI takes precedence.
  CliConfig merge({
    String? spec,
    String? outputDir,
    String? packageName,
    LogLevel? logLevel,
  }) {
    return CliConfig(
      spec: spec ?? this.spec,
      outputDir: outputDir ?? this.outputDir,
      packageName: packageName ?? this.packageName,
      logLevel: logLevel ?? this.logLevel,
      nameOverrides: nameOverrides,
      contentTypes: contentTypes,
      contentMediaTypes: contentMediaTypes,
      filter: filter,
      deprecated: this.deprecated,
      enums: enums,
    );
  }
}

/// Exception thrown when configuration loading fails.
class ConfigLoaderException implements Exception {
  ConfigLoaderException(this.message);

  final String message;

  @override
  String toString() => message;
}
