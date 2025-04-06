import 'package:change_case/change_case.dart';
import 'package:tonic_core/tonic_core.dart';

/// A manager for handling unique names in generated Dart code.
class NameGenerator {
  NameGenerator();

  static const _modelSuffix = 'Model';
  static const _responseSuffix = 'Response';
  static const _operationSuffix = 'Operation';
  static const _apiSuffix = 'Api';

  final _usedNames = <String>{};

  /// Generates a unique class name for a model.
  ///
  /// Names are generated with the following priority:
  /// 1. Model's explicit name if available
  /// 2. Combined context path components
  /// 3. 'Anonymous' as fallback
  String generateModelName(Model model) {
    String? name;
    if (model is NamedModel) {
      name = model.name;
    }

    final baseName = _generateBaseName(name: name, context: model.context);
    return _makeUnique(baseName, _modelSuffix);
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
    return _makeUnique(baseName, _responseSuffix);
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
    return _makeUnique(baseName, _operationSuffix);
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
  /// then appending an incrementing number if necessary.
  ///
  /// Example with Model suffix: [User, User, User]
  /// → [User, UserModel, UserModel2]
  /// Example with Response suffix: [User, User]
  /// → [User, UserResponse, UserResponse2]
  String _makeUnique(String name, String suffix) {
    if (!_usedNames.contains(name)) {
      _usedNames.add(name);
      return name;
    }

    final baseName = name.endsWith(suffix) ? name : '$name$suffix';

    if (!name.endsWith(suffix) && !_usedNames.contains(baseName)) {
      _usedNames.add(baseName);
      return baseName;
    }

    return _addNumberSuffix(baseName);
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
}
