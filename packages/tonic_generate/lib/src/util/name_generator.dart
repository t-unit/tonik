import 'package:change_case/change_case.dart';
import 'package:tonic_core/tonic_core.dart';

/// A manager for handling unique names in generated Dart code.
class NameGenerator {
  NameGenerator();

  static const _modelSuffix = 'Model';
  static const _responseSuffix = 'Response';
  static const _headerSuffix = 'Header';
  static const _parameterSuffix = 'Parameter';
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
    if (model case final NamedModel named) {
      name = named.name;
    }
    
    final baseName = _generateBaseName(
      name: name,
      context: model.context,
    );
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

  /// Generates a unique name for a response header.
  /// 
  /// Names are generated with the following priority:
  /// 1. Header's explicit name if available
  /// 2. Combined context path components
  /// 3. 'Anonymous' as fallback
  String generateResponseHeaderName(ResponseHeader header) {
    final baseName = _generateBaseName(
      name: header.name,
      context: header.context,
    );
    return _makeUnique(baseName, _headerSuffix);
  }

  /// Generates a unique name for a request header.
  /// 
  /// Names are generated with the following priority:
  /// 1. Header's explicit name if available
  /// 2. Combined context path components
  /// 3. 'Anonymous' as fallback
  String generateRequestHeaderName(RequestHeader header) {
    String? name;
    if (header case final RequestHeaderObject obj) {
      name = obj.name;
    } else if (header case final RequestHeaderAlias alias) {
      name = alias.name;
    }
    
    final baseName = _generateBaseName(
      name: name,
      context: header.context,
    );
    return _makeUnique(baseName, _headerSuffix);
  }

  /// Generates a unique name for a query parameter.
  /// 
  /// Names are generated with the following priority:
  /// 1. Parameter's explicit name if available
  /// 2. Combined context path components
  /// 3. 'Anonymous' as fallback
  String generateQueryParameterName(QueryParameter parameter) {
    String? name;
    if (parameter case final QueryParameterObject obj) {
      name = obj.name;
    } else if (parameter case final QueryParameterAlias alias) {
      name = alias.name;
    }
    
    final baseName = _generateBaseName(
      name: name,
      context: parameter.context,
    );
    return _makeUnique(baseName, _parameterSuffix);
  }

  /// Generates a unique name for a path parameter.
  /// 
  /// Names are generated with the following priority:
  /// 1. Parameter's explicit name if available
  /// 2. Combined context path components
  /// 3. 'Anonymous' as fallback
  String generatePathParameterName(PathParameter parameter) {
    String? name;
    if (parameter case final PathParameterObject obj) {
      name = obj.name;
    } else if (parameter case final PathParameterAlias alias) {
      name = alias.name;
    }
    
    final baseName = _generateBaseName(
      name: name,
      context: parameter.context,
    );
    return _makeUnique(baseName, _parameterSuffix);
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
  String _generateBaseName({
    required String? name,
    required Context context,
  }) {
    if (name != null && name.isNotEmpty) {
      return _sanitizeName(name);
    }

    final path = context.path;
    if (path.isNotEmpty) {
      return path.map(_sanitizeName).join();
    }

    return 'Anonymous';
  }

  /// Sanitizes a name for use as a Dart class name.
  /// 
  /// Examples:
  /// - 'my_class_name' → 'MyClassName'
  /// - '_my_class_name' → 'MyClassName'
  /// - 'hello_world_test' → 'HelloWorldTest'
  /// - 'Model23' → 'Model23'
  /// - '2Model' → 'Model'
  /// - '2_Model12String33' → 'Model12String33'
  String _sanitizeName(String name) {
    var cleaned = name.replaceAll('-', '_');
    cleaned = cleaned.replaceAll(RegExp(r'[^\w]'), '');
    cleaned = cleaned.replaceFirst(RegExp('^_+'), '');
    
    cleaned = cleaned.split(RegExp(r'[_\s]+')).map((part) {
      part = part.replaceFirst(RegExp(r'^\d+'), '');
      if (part.isEmpty) return '';
      
      return part.toPascalCase();
    }).where((part) => part.isNotEmpty).join();
    
    if (RegExp(r'^\d').hasMatch(cleaned)) {
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
