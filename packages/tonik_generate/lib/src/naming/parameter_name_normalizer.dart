import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';

const _pathSuffix = 'Path';
const _querySuffix = 'Query';
const _headerSuffix = 'Header';
const _cookieSuffix = 'Cookie';
const _defaultParameterPrefix = 'parameter';

/// `cancelToken` is reserved because the generated `call(...)` method
/// always declares a built-in `CancelToken? cancelToken` parameter.
/// `body` is reserved only when a request body exists, since `call(...)`
/// then also declares a `body` parameter.
Set<String> operationReservedParameterNames({required bool hasRequestBody}) => {
  if (hasRequestBody) 'body',
  'cancelToken',
};

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

  // Parameters that collide across locations get a location suffix.
  final resolvedPathParams = normalizedPathParams
      .map((item) => _applySuffix(item, nameInTypes, _pathSuffix))
      .toList();

  final resolvedQueryParams = normalizedQueryParams
      .map((item) => _applySuffix(item, nameInTypes, _querySuffix))
      .toList();

  final resolvedHeaderParams = normalizedHeaders
      .map((item) => _applySuffix(item, nameInTypes, _headerSuffix))
      .toList();

  final resolvedCookieParams = normalizedCookies
      .map((item) => _applySuffix(item, nameInTypes, _cookieSuffix))
      .toList();

  final assigner = _NameAssigner(
    totalParameterCount:
        resolvedPathParams.length +
        resolvedQueryParams.length +
        resolvedHeaderParams.length +
        resolvedCookieParams.length,
    reservedNames: reservedNames,
  );

  final pathNames = List<String?>.filled(resolvedPathParams.length, null);
  final queryNames = List<String?>.filled(resolvedQueryParams.length, null);
  final headerNames = List<String?>.filled(resolvedHeaderParams.length, null);
  final cookieNames = List<String?>.filled(resolvedCookieParams.length, null);

  // Unsuffixed names are claimed across all locations first so a declared
  // parameter keeps its own name; a synthesized (suffixed) name that lands
  // on a declared one disambiguates further with a counter.
  for (final suffixedPass in [false, true]) {
    assigner
      ..claimInto(resolvedPathParams, pathNames, suffixedPass: suffixedPass)
      ..claimInto(resolvedQueryParams, queryNames, suffixedPass: suffixedPass)
      ..claimInto(resolvedHeaderParams, headerNames, suffixedPass: suffixedPass)
      ..claimInto(
        resolvedCookieParams,
        cookieNames,
        suffixedPass: suffixedPass,
      );
  }

  return NormalizedRequestParameters(
    pathParameters: [
      for (var i = 0; i < resolvedPathParams.length; i++)
        (
          normalizedName: pathNames[i]!,
          parameter: resolvedPathParams[i].parameter,
        ),
    ],
    queryParameters: [
      for (var i = 0; i < resolvedQueryParams.length; i++)
        (
          normalizedName: queryNames[i]!,
          parameter: resolvedQueryParams[i].parameter,
        ),
    ],
    headers: [
      for (var i = 0; i < resolvedHeaderParams.length; i++)
        (
          normalizedName: headerNames[i]!,
          parameter: resolvedHeaderParams[i].parameter,
        ),
    ],
    cookieParameters: [
      for (var i = 0; i < resolvedCookieParams.length; i++)
        (
          normalizedName: cookieNames[i]!,
          parameter: resolvedCookieParams[i].parameter,
        ),
    ],
  );
}

({String normalizedName, bool wasSuffixed, T parameter}) _applySuffix<T>(
  ({String normalizedName, T parameter}) item,
  Map<String, Set<String>> nameInTypes,
  String suffix,
) {
  final lowerName = item.normalizedName.toLowerCase();
  if (nameInTypes[lowerName]!.length > 1) {
    return (
      normalizedName: '${item.normalizedName}$suffix',
      wasSuffixed: true,
      parameter: item.parameter,
    );
  }
  return (
    normalizedName: item.normalizedName,
    wasSuffixed: false,
    parameter: item.parameter,
  );
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
  final normalized = normalizeSingle(name, preserveNumbers: true);
  return normalized.isEmpty ? _defaultParameterPrefix : normalized;
}

/// Assigns final parameter names, unique (case-insensitively) across all
/// locations and reserved names.
class _NameAssigner {
  _NameAssigner({
    required int totalParameterCount,
    required Set<String> reservedNames,
  }) : _convergenceBound = totalParameterCount + reservedNames.length + 2 {
    _usedNames.addAll(reservedNames.map((name) => name.toLowerCase()));
  }

  final Set<String> _usedNames = <String>{};
  final Map<String, int> _nameCounters = <String, int>{};

  // Worst case: all names share the same base, so the maximum counter value
  // reached is the total name count. The +2 buffer gives headroom and matches
  // the initial counter value of 2.
  final int _convergenceBound;

  void claimInto<T>(
    List<({String normalizedName, bool wasSuffixed, T parameter})> group,
    List<String?> names, {
    required bool suffixedPass,
  }) {
    for (var i = 0; i < group.length; i++) {
      if (group[i].wasSuffixed == suffixedPass) {
        names[i] = _claim(group[i].normalizedName);
      }
    }
  }

  String _claim(String baseName) {
    final baseLowerName = baseName.toLowerCase();

    var name = baseName;
    var lowerName = baseLowerName;

    _nameCounters.putIfAbsent(baseLowerName, () => 2);

    // Loop (not single increment) because a counter-generated candidate may
    // itself collide with an earlier entry: [tokenQuery, tokenQuery2,
    // tokenQuery] — naive increment yields tokenQuery2, which already exists.
    while (_usedNames.contains(lowerName)) {
      final counter = _nameCounters[baseLowerName]!;
      if (counter > _convergenceBound) {
        throw StateError(
          'Counter for "$baseName" exceeded the total name count + 2 '
          '($_convergenceBound); _NameAssigner is not converging — '
          'counter increment is broken.',
        );
      }
      name = '$baseName$counter';
      lowerName = name.toLowerCase();
      _nameCounters[baseLowerName] = counter + 1;
    }

    _usedNames.add(lowerName);
    return name;
  }
}
