import 'package:change_case/change_case.dart';
import 'package:tonik_core/tonik_core.dart';

/// A manager for handling unique names in generated Dart code.
class NameGenerator {
  NameGenerator();

  static const _modelSuffix = 'Model';
  static const _responseSuffix = 'Response';
  static const _operationSuffix = 'Operation';
  static const _apiSuffix = 'Api';
  static const _requestBodySuffix = 'RequestBody';

  final _usedNames = <String>{};

  /// Generates a unique class name for a model.
  ///
  /// Names are generated with the following priority:
  /// 1. Model's explicit name if available
  /// 2. Model type-based name for primitive models
  /// 3. Combined context path components
  /// 4. 'Anonymous' as fallback
  /// Generates a unique variant name for composite models
  /// (OneOf, AnyOf, AllOf).
  ///
  /// This method handles the specific naming requirements for variant classes
  /// within composite models, ensuring proper uniqueness tracking.
  String generateVariantName(
    String parentClassName,
    Model model,
    String? discriminatorValue,
  ) {
    if (model is NamedModel && model.name != null && model.name!.isNotEmpty) {
      final sanitizedName = _sanitizeName(model.name!);
      final variantName = '$parentClassName$sanitizedName';
      return _makeUnique(variantName, '');
    }

    final rawName = discriminatorValue ?? generateDiscriminatorName(model);
    final variantName = '$parentClassName${rawName.toPascalCase()}';
    return _makeUnique(variantName, '');
  }

  String generateModelName(Model model) {
    String? name;
    if (model is NamedModel) {
      name = model.name;
    }

    String baseName;
    if (name == null || name.isEmpty) {
      final typeBasedName = _getPrimitiveModelName(model);
      if (typeBasedName != null) {
        baseName = typeBasedName;
      } else {
        baseName = _generateBaseName(name: name, context: model.context);
      }
    } else {
      baseName = _generateBaseName(name: name, context: model.context);
    }

    if (name == null || name.isEmpty) {
      final typeSuffix = switch (model) {
        AllOfModel() => 'AllOf',
        OneOfModel() => 'OneOf',
        AnyOfModel() => 'AnyOf',
        PrimitiveModel() => '',
        _ => 'Model',
      };

      if (typeSuffix.isNotEmpty && !baseName.endsWith(typeSuffix)) {
        baseName = '$baseName$typeSuffix';
      }
      return _makeUnique(baseName, _modelSuffix);
    } else {
      return _makeUniqueWithTypeSuffix(baseName, _modelSuffix);
    }
  }

  /// Get a type-based name for primitive models
  String? _getPrimitiveModelName(Model model) {
    return switch (model) {
      StringModel() => 'String',
      IntegerModel() => 'Int',
      BooleanModel() => 'Bool',
      NumberModel() => 'Number',
      DateModel() => 'Date',
      DateTimeModel() => 'DateTime',
      DoubleModel() => 'Double',
      DecimalModel() => 'Decimal',
      UriModel() => 'Uri',
      _ => null,
    };
  }

  /// Generates a meaningful discriminator name based on the model type.
  ///
  /// This method is used by composite models (OneOf, AllOf, AnyOf) to generate
  /// meaningful discriminator names for their variants when no explicit
  /// discriminator value is provided.
  ///
  /// Examples:
  /// - StringModel → 'string'
  /// - AllOfModel → 'allOf'
  /// - ClassModel with name 'User' → 'User'
  /// - ClassModel without name → 'class'
  /// - Model with alias → uses alias name
  String generateDiscriminatorName(Model model) {
    return switch (model) {
      AliasModel() => _sanitizeName(model.name),
      StringModel() => 'string',
      IntegerModel() => 'int',
      BooleanModel() => 'bool',
      NumberModel() => 'number',
      DateModel() => 'date',
      DateTimeModel() => 'dateTime',
      DoubleModel() => 'double',
      DecimalModel() => 'decimal',
      UriModel() => 'uri',
      AllOfModel() => model.name ?? 'allOf',
      AnyOfModel() => model.name ?? 'anyOf',
      OneOfModel() => model.name ?? 'oneOf',
      ClassModel() => model.name ?? 'class',
      EnumModel() => model.name ?? 'enum',
      ListModel() => 'list',
      _ => 'unknown',
    };
  }

  /// Generates a unique response class name from a Response object.
  ///
  /// Names are generated with the following priority:
  /// 1. Response's explicit name if available
  /// 2. Combined context path components
  /// 3. 'Anonymous' as fallback
  String generateResponseName(Response response) {
    final baseName = _generateBaseName(
      name: response.name,
      context: response.context,
    );

    // Only add Response suffix for anonymous responses
    if (response.name == null || (response.name?.isEmpty ?? false)) {
      return _makeUnique(baseName, _responseSuffix);
    } else {
      return _makeUniqueWithTypeSuffix(baseName, _responseSuffix);
    }
  }

  /// Generates a unique name for an operation.
  ///
  /// Names are generated with the following priority:
  /// 1. Operation's operationId if available
  /// 2. Combined context path components
  /// 3. 'Anonymous' as fallback
  String generateOperationName(Operation operation) {
    final baseName = _generateBaseName(
      name: operation.operationId,
      context: operation.context,
    );
    return _makeUniqueWithTypeSuffix(baseName, _operationSuffix);
  }

  /// Generates a unique API class name for a tag.
  String generateTagName(Tag tag) {
    final baseName = _sanitizeName(tag.name);
    final nameWithSuffix = '$baseName$_apiSuffix';

    if (!_usedNames.contains(nameWithSuffix)) {
      _usedNames.add(nameWithSuffix);
      return nameWithSuffix;
    }

    return _addNumberSuffix(nameWithSuffix);
  }

  /// Generates a unique request body class name.
  ///
  /// Names are generated with the following priority:
  /// 1. Request body's explicit name if available
  /// 2. Combined context path components
  /// 3. 'Anonymous' as fallback
  ///
  /// For request bodies with multiple content types, this will generate
  /// a base class name and subclass names for each content type.
  /// Returns a record with the base name and a map of content types
  /// to subclass names.
  (String baseName, Map<String, String> subclassNames) generateRequestBodyNames(
    RequestBody requestBody,
  ) {
    final baseName = _generateBaseName(
      name: requestBody.name,
      context: requestBody.context,
    );

    // Only add RequestBody suffix for anonymous request bodies
    final uniqueBaseName =
        requestBody.name == null || (requestBody.name?.isEmpty ?? false)
            ? _makeUnique(baseName, _requestBodySuffix)
            : _makeUniqueWithTypeSuffix(baseName, _requestBodySuffix);

    final subclassNames = <String, String>{};
    if (requestBody is RequestBodyObject && requestBody.contentCount > 1) {
      for (final content in requestBody.resolvedContent) {
        final suffix =
            content.rawContentType.split('/').lastOrNull?.toPascalCase() ??
            'Default';
        final subclassBaseName = '$uniqueBaseName$suffix';
        subclassNames[content.rawContentType] = _makeUnique(
          subclassBaseName,
          '',
        );
      }
    }

    return (uniqueBaseName, subclassNames);
  }

  /// Generates a unique response wrapper base class name and subclass names
  /// for each response status.
  ///
  /// Returns a record with the base name and a map of ResponseStatus keys
  /// to subclass names.
  (String baseName, Map<ResponseStatus, String> subclassNames)
  generateResponseWrapperNames(
    String operationName,
    Map<ResponseStatus, Response> responses,
  ) {
    String statusSuffix(ResponseStatus status) {
      if (status is ExplicitResponseStatus) {
        return status.statusCode.toString();
      } else if (status is DefaultResponseStatus) {
        return 'Default';
      } else if (status is RangeResponseStatus) {
        final min = status.min;
        final max = status.max;
        if (min % 100 == 0 && max == min + 99) {
          return '${min ~/ 100}XX';
        }
        return '${min}To$max';
      }
      return 'Unknown';
    }

    final baseName = _makeUniqueWithTypeSuffix(
      '${operationName}Response',
      'Wrapper',
    );

    final subclassNames = <ResponseStatus, String>{};
    for (final entry in responses.entries) {
      final status = entry.key;
      final statusSuffixStr = statusSuffix(status);
      final subclassName = '$baseName$statusSuffixStr';
      subclassNames[status] = _makeUnique(subclassName, '');
    }
    return (baseName, subclassNames);
  }

  /// Generates a unique implementation name for a response body.
  ///
  /// The name is based on the base response name and the content type.
  /// For example, a response named "UserResponse" with content type
  /// "application/json" would generate "UserResponseJson".
  ///
  /// If multiple responses have the same content type, numbers are appended
  /// to make the names unique.
  String generateResponseImplementationName(
    String baseName,
    ResponseBody body,
  ) {
    final contentType = body.rawContentType.split('/').lastOrNull;
    if (contentType == null) {
      return _makeUnique(baseName, '');
    }

    // Handle version numbers in content type (e.g. application/json+v2)
    final parts = contentType.split('+');
    final baseContentType = parts.first;
    final version = parts.length > 1 ? parts.last : null;

    final suffix = baseContentType.toPascalCase();
    final versionSuffix = version != null ? version.toPascalCase() : '';
    final fullSuffix = '$suffix$versionSuffix';

    return _makeUnique(baseName, fullSuffix);
  }

  /// Generates a base name using the following priority:
  /// 1. Explicit name if available
  /// 2. Combined context path components
  /// 3. 'Anonymous' as fallback
  String _generateBaseName({required String? name, required Context context}) {
    if (name != null && name.isNotEmpty) {
      return _sanitizeName(name);
    }

    final path = context.path;
    if (path.isEmpty) {
      return 'Anonymous';
    }

    // Filter path components.
    final filteredPath = _removeOpenApiPrefixes(path);
    if (filteredPath.isEmpty) {
      return 'Anonymous';
    }

    return filteredPath
        .map((part) => _sanitizeName(part, isPathComponent: true))
        .join();
  }

  /// Removes OpenAPI-specific prefixes from a context path
  List<String> _removeOpenApiPrefixes(List<String> path) {
    if (path.isEmpty) {
      return path;
    }

    if (path.first == 'paths') {
      return path.skip(1).toList();
    }

    if (path.length >= 2 && path[0] == 'components') {
      final secondComponent = path[1];
      if ([
        'schemas',
        'requestBodies',
        'responses',
        'parameters',
        'headers',
        'pathItems',
      ].contains(secondComponent)) {
        return path.skip(2).toList();
      }
    }

    return path;
  }

  /// Sanitizes a name for use as a Dart class name.
  ///
  /// Examples:
  /// - 'my_class_name' → 'MyClassName'
  /// - '_my_class_name' → 'MyClassName'
  /// - 'hello_world_test' → 'HelloWorldTest'
  /// - 'Model23' → 'Model23'
  /// - '2Model' → 'Model' (for full names)
  /// - '200' → '200' (for context path components)
  /// - '2_Model12String33' → 'Model12String33' (for full names)
  /// - 'X-Rate-Limit' → 'RateLimit' (for headers with X prefix)
  String _sanitizeName(String name, {bool isPathComponent = false}) {
    // Handle common header prefix pattern (X-Something)
    var inputName = name;
    if (inputName.startsWith('X-') || inputName.startsWith('x-')) {
      inputName = inputName.substring(2);
    }

    var cleaned = inputName.replaceAll('-', '_');
    cleaned = cleaned.replaceAll(RegExp(r'[^\w]'), '');
    cleaned = cleaned.replaceFirst(RegExp('^_+'), '');

    if (isPathComponent && RegExp(r'^\d+$').hasMatch(cleaned)) {
      return cleaned;
    }

    if (isPathComponent && cleaned.startsWith('x_')) {
      cleaned = cleaned.substring(2);
    }

    cleaned =
        cleaned
            .split(RegExp(r'[_\s]+'))
            .map((part) {
              if (!isPathComponent) {
                part = part.replaceFirst(RegExp(r'^\d+'), '');
              }
              if (part.isEmpty) return '';

              return part.toPascalCase();
            })
            .where((part) => part.isNotEmpty)
            .join();

    if (!isPathComponent && RegExp(r'^\d').hasMatch(cleaned)) {
      cleaned = cleaned.replaceFirst(RegExp(r'^\d+'), '');
    }

    if (cleaned.isEmpty) {
      cleaned = 'Anonymous';
    }

    return cleaned;
  }

  /// Makes a name unique by first trying to add the given suffix,
  /// then appending appropriate type-specific suffix for 
  /// conflicts, then numeric suffixes.
  ///
  /// Example with Model suffix: [User, User, User]
  /// → [User, UserModel, UserModel2]
  /// Example with Response suffix: [User, User]
  /// → [User, UserResponse, UserResponse2]
  String _makeUnique(String name, String suffix) {
    if (suffix.isEmpty) {
      if (!_usedNames.contains(name)) {
        _usedNames.add(name);
        return name;
      }

      final nameWithModel =
          name.endsWith(_modelSuffix) ? name : '$name$_modelSuffix';
      if (!_usedNames.contains(nameWithModel)) {
        _usedNames.add(nameWithModel);
        return nameWithModel;
      }

      return _addNumberSuffix(nameWithModel);
    }

    final nameWithSuffix = name.endsWith(suffix) ? name : '$name$suffix';

    if (!_usedNames.contains(nameWithSuffix)) {
      _usedNames.add(nameWithSuffix);
      return nameWithSuffix;
    }

    return _addNumberSuffix(nameWithSuffix);
  }

  /// Makes a name unique by first trying the name as-is,
  /// then adding the type-specific suffix for conflicts.
  String _makeUniqueWithTypeSuffix(String name, String typeSuffix) {
    if (!_usedNames.contains(name)) {
      _usedNames.add(name);
      return name;
    }

    final nameWithTypeSuffix =
        name.endsWith(typeSuffix) ? name : '$name$typeSuffix';
    if (!_usedNames.contains(nameWithTypeSuffix)) {
      _usedNames.add(nameWithTypeSuffix);
      return nameWithTypeSuffix;
    }

    return _addNumberSuffix(nameWithTypeSuffix);
  }

  /// Makes a name unique by first trying the name as-is,
  /// then adding numeric suffixes.
  String _makeUniqueWithNumericSuffix(String name) {
    if (!_usedNames.contains(name)) {
      _usedNames.add(name);
      return name;
    }
    return _addNumberSuffix(name);
  }

  String _addNumberSuffix(String baseName) {
    var counter = 2;
    String uniqueName;

    do {
      uniqueName = '$baseName$counter';
      counter++;
    } while (_usedNames.contains(uniqueName));

    _usedNames.add(uniqueName);
    return uniqueName;
  }

  /// Generates names for a list of servers based on their domains.
  ///
  /// Returns a record with the server map and a custom server name.
  ({String baseName, Map<Server, String> serverMap, String customName})
  generateServerNames(List<Server> servers) {
    // Try to parse all server URLs
    final parsedUrls = <Uri>[];
    try {
      for (final server in servers) {
        parsedUrls.add(Uri.parse(server.url));
      }
    } on Exception {
      return _generateFallbackServerNames(servers);
    }

    final subdomains =
        parsedUrls.map((uri) {
          final hostParts = uri.host.split('.');
          if (hostParts.length > 2) {
            // For multi-level subdomains, combine all subdomain parts
            // e.g., api.dev.example.com -> ApiDev
            final subdomain =
                hostParts
                    .sublist(0, hostParts.length - 2)
                    .map(_sanitizeName)
                    .join('_')
                    .toPascalCase();
            return subdomain;
          } else {
            // For single-level subdomains like api.example.com,
            // just use the first part
            return _sanitizeName(hostParts.first);
          }
        }).toList();
    final hosts =
        parsedUrls.map((uri) {
          final parts = uri.host.split('.');
          return parts.length > 1 ? _sanitizeName(parts[parts.length - 2]) : '';
        }).toList();
    final paths = parsedUrls.map((uri) => _sanitizeName(uri.path)).toList();

    final hasDuplicateSubdomains =
        subdomains.toSet().length != subdomains.length;
    final hasDuplicateHosts = hosts.toSet().length != hosts.length;
    final hasDuplicatePaths = paths.toSet().length != paths.length;

    if (!hasDuplicateSubdomains) {
      return _generateServerNames(servers, subdomains);
    } else if (!hasDuplicateHosts) {
      return _generateServerNames(servers, hosts);
    } else if (!hasDuplicatePaths) {
      return _generateServerNames(servers, paths);
    } else {
      return _generateFallbackServerNames(servers);
    }
  }

  ({String baseName, Map<Server, String> serverMap, String customName})
  _generateServerNames(List<Server> servers, List<String> uniqueNames) {
    final baseName = _makeUniqueWithNumericSuffix('Server');

    final resultMap = <Server, String>{};
    for (var index = 0; index < servers.length; index++) {
      final server = servers[index];
      final name = uniqueNames[index];
      resultMap[server] = _makeUniqueWithNumericSuffix('${name}Server');
    }

    final customName =
        resultMap.values.contains('CustomServer')
            ? r'CustomServer$'
            : 'CustomServer';
    return (
      baseName: baseName,
      serverMap: resultMap,
      customName: _makeUnique(customName, ''),
    );
  }

  ({String baseName, Map<Server, String> serverMap, String customName})
  _generateFallbackServerNames(List<Server> servers) {
    final baseName = _makeUniqueWithNumericSuffix('Server');

    final resultMap = <Server, String>{};
    for (final server in servers) {
      resultMap[server] = _makeUniqueWithNumericSuffix('Server');
    }
    return (
      baseName: baseName,
      serverMap: resultMap,
      customName: _makeUniqueWithNumericSuffix('CustomServer'),
    );
  }
}
