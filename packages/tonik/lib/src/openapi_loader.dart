import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

Logger logger = Logger('openapi_loader');

/// Loads and parses an OpenAPI document from a file.
/// Supports both JSON and YAML formats.
///
/// Returns a Map representation of the OpenAPI document.
Map<String, dynamic> loadOpenApiDocument(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw OpenApiLoaderException('OpenAPI document not found');
  }

  final content = file.readAsStringSync();
  final extension = path.toLowerCase().split('.').last;

  try {
    final apiSpec = switch (extension) {
      'json' => json.decode(content) as Map<String, dynamic>,
      'yaml' || 'yml' => _convertYamlToMap(loadYaml(content)),
      _ => throw OpenApiLoaderException(
        'Unsupported file extension: .$extension. '
        'Must be .json, .yaml, or .yml',
      ),
    };

    logger.fine('Parsed OpenAPI document as ${extension.toUpperCase()}');

    return apiSpec;
  } on Object catch (e) {
    logger.fine('Failed to parse OpenAPI document. $e');
    throw OpenApiLoaderException('Failed to parse OpenAPI document.');
  }
}

/// Converts a YAML document to a Map
Map<String, dynamic> _convertYamlToMap(dynamic yaml) {
  if (yaml is! YamlMap) {
    throw OpenApiLoaderException('Root of OpenAPI document must be an object');
  }
  return _convertYamlNode(yaml) as Map<String, dynamic>;
}

/// Recursively converts YAML nodes to JSON-compatible types
dynamic _convertYamlNode(dynamic yaml) {
  if (yaml is YamlMap) {
    return yaml.map(
      (key, value) => MapEntry(key.toString(), _convertYamlNode(value)),
    );
  }
  if (yaml is YamlList) {
    return yaml.map(_convertYamlNode).toList();
  }
  return yaml;
}

class OpenApiLoaderException implements Exception {
  OpenApiLoaderException(this.message);

  final String message;

  @override
  String toString() => message;
}
