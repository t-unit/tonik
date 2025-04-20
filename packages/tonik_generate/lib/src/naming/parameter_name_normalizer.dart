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

  final nameOccurrences = <String, int>{};

  // Count occurrences of each name across all parameter types
  for (final item in normalizedPathParams) {
    final lowerName = item.normalizedName.toLowerCase();
    nameOccurrences[lowerName] = (nameOccurrences[lowerName] ?? 0) + 1;
  }

  for (final item in normalizedQueryParams) {
    final lowerName = item.normalizedName.toLowerCase();
    nameOccurrences[lowerName] = (nameOccurrences[lowerName] ?? 0) + 1;
  }

  for (final item in normalizedHeaders) {
    final lowerName = item.normalizedName.toLowerCase();
    nameOccurrences[lowerName] = (nameOccurrences[lowerName] ?? 0) + 1;
  }

  // Add suffixes to all parameters with duplicate names across types
  final resolvedPathParams =
      normalizedPathParams.map((item) {
        final lowerName = item.normalizedName.toLowerCase();
        if (nameOccurrences[lowerName]! > 1) {
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
        if (nameOccurrences[lowerName]! > 1) {
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
        if (nameOccurrences[lowerName]! > 1) {
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
  final nameCounters = <String, int>{}; // lowercase name -> counter

  for (final item in parameters) {
    var name = item.normalizedName;
    var lowerName = name.toLowerCase();

    // If the name is already used, add a numeric suffix
    if (usedNames.contains(lowerName)) {
      final counter = nameCounters.putIfAbsent(lowerName, () => 2);
      name = '$name$counter';
      lowerName = name.toLowerCase();
      nameCounters[lowerName] = counter + 1;
    }

    usedNames.add(lowerName);
    result.add((normalizedName: name, parameter: item.parameter));
  }

  return result;
}

/// Normalizes path parameter names.
List<({String normalizedName, PathParameterObject parameter})>
_normalizePathParameters(Set<PathParameterObject> parameters) {
  return parameters
      .map(
        (param) => (
          normalizedName: _normalizeName(param.rawName),
          parameter: param,
        ),
      )
      .toList();
}

/// Normalizes query parameter names.
List<({String normalizedName, QueryParameterObject parameter})>
_normalizeQueryParameters(Set<QueryParameterObject> parameters) {
  return parameters
      .map(
        (param) => (
          normalizedName: _normalizeName(param.rawName),
          parameter: param,
        ),
      )
      .toList();
}

/// Normalizes header parameter names, removing any 'x-' prefix.
List<({String normalizedName, RequestHeaderObject parameter})>
_normalizeHeaderParameters(Set<RequestHeaderObject> parameters) {
  return parameters
      .map(
        (param) => (
          normalizedName: _normalizeHeaderName(param.rawName),
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
