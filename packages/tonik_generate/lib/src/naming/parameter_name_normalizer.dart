import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';

const _pathSuffix = 'Path';
const _querySuffix = 'Query';
const _headerSuffix = 'Header';
const _cookieSuffix = 'Cookie';

/// `cancelToken` is reserved because the generated `call(...)` method
/// always declares a built-in `CancelToken? cancelToken` parameter.
/// `body` is reserved only when a request body exists, since `call(...)`
/// then also declares a `body` parameter.
Set<String> operationReservedParameterNames({required bool hasRequestBody}) =>
    {if (hasRequestBody) 'body', 'cancelToken'};

/// Result of normalizing request parameters.
class NormalizedRequestParameters {
  const NormalizedRequestParameters({
    required this.pathParameters,
    required this.queryParameters,
    required this.headers,
    required this.cookieParameters,
  });

  final List<({String normalizedName, PathParameterObject parameter})>
  pathParameters;
  final List<({String normalizedName, QueryParameterObject parameter})>
  queryParameters;
  final List<({String normalizedName, RequestHeaderObject parameter})> headers;
  final List<({String normalizedName, CookieParameterObject parameter})>
  cookieParameters;

  @override
  String toString() {
    return 'NormalizedRequestParameters(pathParameters: $pathParameters, '
        'queryParameters: $queryParameters, headers: $headers, '
        'cookieParameters: $cookieParameters)';
  }
}

/// Normalizes request parameters from path, query, header, and
/// cookie parameters.
///
/// Makes sure names are not duplicated across parameter types.
/// Adds appropriate type suffixes if needed.
/// For headers, removes 'x-' prefixes.
NormalizedRequestParameters normalizeRequestParameters({
  required Set<PathParameterObject> pathParameters,
  required Set<QueryParameterObject> queryParameters,
  required Set<RequestHeaderObject> headers,
  Set<CookieParameterObject> cookieParameters = const {},
  Set<String> reservedNames = const {},
}) {
  final normalizedPathParams = _normalizePathParameters(pathParameters);
  final normalizedQueryParams = _normalizeQueryParameters(queryParameters);
  final normalizedHeaders = _normalizeHeaderParameters(headers);
  final normalizedCookies = _normalizeCookieParameters(cookieParameters);

  // Track which parameter types contain each name.
  final nameInTypes = <String, Set<String>>{};

  // Seed with reserved names so parameters that collide with them
  // get a type suffix (e.g., a query param named 'body' becomes
  // 'bodyQuery' when 'body' is reserved by the request body).
  for (final reserved in reservedNames) {
    nameInTypes
        .putIfAbsent(reserved.toLowerCase(), () => <String>{})
        .add('reserved');
  }

  // Count occurrences per type.
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

  for (final item in normalizedCookies) {
    final lowerName = item.normalizedName.toLowerCase();
    nameInTypes.putIfAbsent(lowerName, () => <String>{}).add('cookie');
  }

  // Add suffixes to all parameters with duplicate names across types
  // (i.e., the same name appears in multiple parameter types)
  final resolvedPathParams = normalizedPathParams.map((item) {
    final lowerName = item.normalizedName.toLowerCase();
    if (nameInTypes[lowerName]!.length > 1) {
      return (
        normalizedName: '${item.normalizedName}$_pathSuffix',
        parameter: item.parameter,
      );
    }
    return item;
  }).toList();

  final resolvedQueryParams = normalizedQueryParams.map((item) {
    final lowerName = item.normalizedName.toLowerCase();
    if (nameInTypes[lowerName]!.length > 1) {
      return (
        normalizedName: '${item.normalizedName}$_querySuffix',
        parameter: item.parameter,
      );
    }
    return item;
  }).toList();

  final resolvedHeaderParams = normalizedHeaders.map((item) {
    final lowerName = item.normalizedName.toLowerCase();
    if (nameInTypes[lowerName]!.length > 1) {
      return (
        normalizedName: '${item.normalizedName}$_headerSuffix',
        parameter: item.parameter,
      );
    }
    return item;
  }).toList();

  final resolvedCookieParams = normalizedCookies
      .map<({String normalizedName, CookieParameterObject parameter})>((item) {
        final lowerName = item.normalizedName.toLowerCase();
        if (nameInTypes[lowerName]!.length > 1) {
          return (
            normalizedName: '${item.normalizedName}$_cookieSuffix',
            parameter: item.parameter,
          );
        }
        return item;
      })
      .toList();

  final uniquePathParams = _ensureUniquenessInGroup(resolvedPathParams);
  final uniqueQueryParams = _ensureUniquenessInGroup(resolvedQueryParams);
  final uniqueHeaderParams = _ensureUniquenessInGroup(resolvedHeaderParams);
  final uniqueCookieParams = _ensureUniquenessInGroup(resolvedCookieParams);

  return NormalizedRequestParameters(
    pathParameters: uniquePathParams,
    queryParameters: uniqueQueryParams,
    headers: uniqueHeaderParams,
    cookieParameters: uniqueCookieParams,
  );
}

List<({String normalizedName, T parameter})> _ensureUniquenessInGroup<T>(
  List<({String normalizedName, T parameter})> parameters,
) {
  final result = <({String normalizedName, T parameter})>[];
  final usedNames = <String>{};
  final nameCounters = <String, int>{};

  // Worst case: all N parameters share the same base, so the maximum
  // counter value reached is N. The +2 buffer gives headroom and matches
  // the initial counter value of 2.
  final convergenceBound = parameters.length + 2;

  for (final item in parameters) {
    final baseName = item.normalizedName;
    final baseLowerName = baseName.toLowerCase();

    var name = baseName;
    var lowerName = baseLowerName;

    nameCounters.putIfAbsent(baseLowerName, () => 2);

    // Loop (not single increment) because a counter-generated candidate may
    // itself collide with an earlier entry: group [tokenQuery, tokenQuery2,
    // tokenQuery] — naive increment yields tokenQuery2, which already exists.
    while (usedNames.contains(lowerName)) {
      final counter = nameCounters[baseLowerName]!;
      if (counter > convergenceBound) {
        throw StateError(
          'Counter for "$baseName" exceeded parameters.length + 2 '
          '($convergenceBound); _ensureUniquenessInGroup is not '
          'converging — counter increment is broken.',
        );
      }
      name = '$baseName$counter';
      lowerName = name.toLowerCase();
      nameCounters[baseLowerName] = counter + 1;
    }

    usedNames.add(lowerName);
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
          normalizedName: param.nameOverride != null
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
          normalizedName: param.nameOverride != null
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
          normalizedName: param.nameOverride != null
              ? _normalizeName(param.nameOverride!)
              : _normalizeHeaderName(param.rawName),
          parameter: param,
        ),
      )
      .toList();
}

/// Normalizes cookie parameter names.
/// Uses nameOverride if set, otherwise normalizes from rawName.
List<({String normalizedName, CookieParameterObject parameter})>
_normalizeCookieParameters(Set<CookieParameterObject> parameters) {
  return parameters
      .map(
        (param) => (
          normalizedName: param.nameOverride != null
              ? _normalizeName(param.nameOverride!)
              : _normalizeName(param.rawName),
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

/// Builds a Dart parameter name for a per-part multipart header by combining
/// the normalized property name with the normalized header name.
///
/// For example: property `profileImage` + header `X-Rate-Limit-Limit`
/// → `profileImageRateLimitLimit`.
String normalizeMultipartHeaderName(
  String normalizedPropertyName,
  String rawHeaderName,
) {
  final normalizedHeader = _normalizeHeaderName(rawHeaderName);
  if (normalizedHeader.isEmpty) return normalizedPropertyName;

  // Capitalize the first letter of the header name so it joins in camelCase.
  final capitalized =
      normalizedHeader[0].toUpperCase() + normalizedHeader.substring(1);
  return '$normalizedPropertyName$capitalized';
}

/// Normalizes a single parameter name.
String _normalizeName(String name) {
  return normalizeSingle(name, preserveNumbers: true);
}
