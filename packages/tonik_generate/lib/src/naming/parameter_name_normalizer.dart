import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';

const _pathSuffix = 'Path';
const _querySuffix = 'Query';
const _headerSuffix = 'Header';

/// Result of normalizing request parameters.
class NormalizedRequestParameters {
  const NormalizedRequestParameters({
    required this.pathParameters,
    required this.queryParameters,
    required this.headers,
  });

  final List<({String normalizedName, PathParameterObject parameter})>
  pathParameters;
  final List<({String normalizedName, QueryParameterObject parameter})>
  queryParameters;
  final List<({String normalizedName, RequestHeaderObject parameter})> headers;

  @override
  String toString() {
    return 'NormalizedRequestParameters(pathParameters: $pathParameters, '
        'queryParameters: $queryParameters, headers: $headers)';
  }
}

/// Normalizes request parameters from path, query, and header parameters.
///
/// Makes sure names are not duplicated across parameter types.
/// Adds appropriate type suffixes if needed.
/// For headers, removes 'x-' prefixes.
NormalizedRequestParameters normalizeRequestParameters({
  required Set<PathParameterObject> pathParameters,
  required Set<QueryParameterObject> queryParameters,
  required Set<RequestHeaderObject> headers,
}) {
  final normalizedPathParams = _normalizePathParameters(pathParameters);
  final normalizedQueryParams = _normalizeQueryParameters(queryParameters);
  final normalizedHeaders = _normalizeHeaderParameters(headers);

  // Track which parameter types contain each name
  final nameInTypes = <String, Set<String>>{};

  // Count occurrences per type
  for (final item in normalizedPathParams) {
    final lowerName = item.normalizedName.toLowerCase();
    nameInTypes.putIfAbsent(lowerName, () => <String>{}).add('path');
  }

  for (final item in normalizedQueryParams) {
    final lowerName = item.normalizedName.toLowerCase();
    nameInTypes.putIfAbsent(lowerName, () => <String>{}).add('query');
  }

  for (final item in normalizedHeaders) {
    final lowerName = item.normalizedName.toLowerCase();
    nameInTypes.putIfAbsent(lowerName, () => <String>{}).add('header');
  }

  // Add suffixes to all parameters with duplicate names across types
  // (i.e., the same name appears in multiple parameter types)
  final resolvedPathParams =
      normalizedPathParams.map((item) {
        final lowerName = item.normalizedName.toLowerCase();
        if (nameInTypes[lowerName]!.length > 1) {
          return (
            normalizedName: '${item.normalizedName}$_pathSuffix',
            parameter: item.parameter,
          );
        }
        return item;
      }).toList();

  final resolvedQueryParams =
      normalizedQueryParams.map((item) {
        final lowerName = item.normalizedName.toLowerCase();
        if (nameInTypes[lowerName]!.length > 1) {
          return (
            normalizedName: '${item.normalizedName}$_querySuffix',
            parameter: item.parameter,
          );
        }
        return item;
      }).toList();

  final resolvedHeaderParams =
      normalizedHeaders.map((item) {
        final lowerName = item.normalizedName.toLowerCase();
        if (nameInTypes[lowerName]!.length > 1) {
          return (
            normalizedName: '${item.normalizedName}$_headerSuffix',
            parameter: item.parameter,
          );
        }
        return item;
      }).toList();

  final uniquePathParams = _ensureUniquenessInGroup(resolvedPathParams);
  final uniqueQueryParams = _ensureUniquenessInGroup(resolvedQueryParams);
  final uniqueHeaderParams = _ensureUniquenessInGroup(resolvedHeaderParams);

  return NormalizedRequestParameters(
    pathParameters: uniquePathParams,
    queryParameters: uniqueQueryParams,
    headers: uniqueHeaderParams,
  );
}

/// Ensures uniqueness of names within a parameter group
List<({String normalizedName, T parameter})> _ensureUniquenessInGroup<T>(
  List<({String normalizedName, T parameter})> parameters,
) {
  final result = <({String normalizedName, T parameter})>[];
  final usedNames = <String>{}; // lowercase names for uniqueness check
  final nameCounters = <String, int>{}; // lowercase base name -> counter

  for (final item in parameters) {
    var name = item.normalizedName;
    final baseLowerName = name.toLowerCase();

    // If the name is already used, add a numeric suffix
    if (usedNames.contains(baseLowerName)) {
      final counter = nameCounters.putIfAbsent(baseLowerName, () => 2);
      name = '$name$counter';
      nameCounters[baseLowerName] = counter + 1;
    }

    usedNames.add(name.toLowerCase());
    result.add((normalizedName: name, parameter: item.parameter));
  }

  return result;
}

/// Normalizes path parameter names.
/// Uses nameOverride if set, otherwise normalizes from rawName.
List<({String normalizedName, PathParameterObject parameter})>
_normalizePathParameters(Set<PathParameterObject> parameters) {
  return parameters
      .map(
        (param) => (
          normalizedName:
              param.nameOverride != null
                  ? _normalizeName(param.nameOverride!)
                  : _normalizeName(param.rawName),
          parameter: param,
        ),
      )
      .toList();
}

/// Normalizes query parameter names.
/// Uses nameOverride if set, otherwise normalizes from rawName.
List<({String normalizedName, QueryParameterObject parameter})>
_normalizeQueryParameters(Set<QueryParameterObject> parameters) {
  return parameters
      .map(
        (param) => (
          normalizedName:
              param.nameOverride != null
                  ? _normalizeName(param.nameOverride!)
                  : _normalizeName(param.rawName),
          parameter: param,
        ),
      )
      .toList();
}

/// Normalizes header parameter names, removing any 'x-' prefix.
/// Uses nameOverride if set, otherwise normalizes from rawName.
List<({String normalizedName, RequestHeaderObject parameter})>
_normalizeHeaderParameters(Set<RequestHeaderObject> parameters) {
  return parameters
      .map(
        (param) => (
          normalizedName:
              param.nameOverride != null
                  ? _normalizeName(param.nameOverride!)
                  : _normalizeHeaderName(param.rawName),
          parameter: param,
        ),
      )
      .toList();
}

/// Normalizes a header name, removing 'x-' prefix if present.
String _normalizeHeaderName(String name) {
  if (name.toLowerCase().startsWith('x-')) {
    return _normalizeName(name.substring(2));
  }
  return _normalizeName(name);
}

/// Normalizes a single parameter name.
String _normalizeName(String name) {
  return normalizeSingle(name, preserveNumbers: true);
}
