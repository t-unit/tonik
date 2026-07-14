import 'package:code_builder/code_builder.dart';
import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/from_form_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';
import 'package:tonik_generate/src/util/response_property_normalizer.dart';
import 'package:tonik_generate/src/util/response_type_generator.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_util/tonik_util.dart' as tonik_util;

class ParseGenerator {
  const ParseGenerator({
    required this.nameManager,
    required this.package,
    this.useImmutableCollections = false,
  });

  final NameManager nameManager;
  final String package;
  final bool useImmutableCollections;

  static final log = Logger('ParseGenerator');

  /// Generates the _parseResponse method for the operation.
  Method generateParseResponseMethod(Operation operation) {
    final responses = operation.responses;
    final responseType = resultTypeForOperation(
      operation,
      nameManager,
      package,
      useImmutableCollections: useImmutableCollections,
    ).types.first;
    final cases = <Code>[];

    var hasDefaultWithNullContentType = false;

    final entries = responses.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in entries) {
      final status = entry.key;
      final response = entry.value;
      final contentTypes = _getContentTypes(response);

      if (status is DefaultResponseStatus && contentTypes.contains(null)) {
        hasDefaultWithNullContentType = true;
      }

      for (final contentType in contentTypes) {
        final casePattern = _casePattern(status, contentType);
        final caseBody = _caseBody(
          operation,
          status,
          response.resolved,
          contentType,
        );
        cases
          ..add(casePattern)
          ..add(caseBody);
      }
    }

    final switchCases = <Code>[
      Block.of([
        const Code(r'final _$mediaType = '),
        refer(
          'extractMediaType',
          'package:tonik_util/tonik_util.dart',
        ).code,
        const Code("(response.headers.value('content-type'));"),
      ]),
      const Code(
        r'switch ((response.statusCode, _$mediaType)) {',
      ),
      ...cases,
    ];

    // A spec `default` response with no content type already matches `(_, _)`,
    // so emitting a synthetic `default:` arm would shadow it and produce dead
    // code.
    if (!hasDefaultWithNullContentType) {
      switchCases.add(
        Block.of([
          const Code('default:'),
          const Code(
            r"final _$content = response.headers.value('content-type') "
            "?? 'not specified';",
          ),
          const Code(r"final _$matched = _$mediaType ?? 'none';"),
          const Code(r'final _$status = response.statusCode;'),
          generateResponseDecodingExceptionExpression(
            'Unexpected content type: '
            r'${_$content}'
            ' (matched as: '
            r'${_$matched}'
            ') for status code: '
            r'${_$status}',
          ).statement,
        ]),
      );
    }

    switchCases.add(const Code('}'));

    final switchBody = Block.of(switchCases);

    return Method(
      (b) => b
        ..name = '_parseResponse'
        ..returns = responseType
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'response'
              ..type = TypeReference(
                (b) => b
                  ..symbol = 'Response'
                  ..url = 'package:dio/dio.dart'
                  ..types.add(
                    TypeReference(
                      (b) => b
                        ..symbol = 'List'
                        ..url = 'dart:core'
                        ..types.add(refer('int', 'dart:core')),
                    ),
                  ),
              ),
          ),
        )
        ..lambda = false
        ..body = switchBody,
    );
  }

  Code _casePattern(ResponseStatus status, String? contentType) {
    // Normalize spec keys with the same helper the generated code uses at
    // runtime so case patterns match the runtime-computed `_$mediaType`.
    final normalized = tonik_util.extractMediaType(contentType);
    final isMediaRange = normalized != null && _isMediaTypeRange(normalized);
    final contentTypePattern = normalized != null && !isMediaRange
        ? specLiteralStringCode(normalized)
        : '_';
    final mediaTypeGuard = isMediaRange
        ? _mediaTypeRangeGuard(normalized)
        : null;

    switch (status) {
      case ExplicitResponseStatus():
        return _caseWithGuards(
          'case (${status.statusCode}, $contentTypePattern)',
          [?mediaTypeGuard],
        );
      case RangeResponseStatus():
        return _caseWithGuards(
          'case (var status, $contentTypePattern)',
          [
            Code(
              'status != null '
              '&& status >= ${status.min} && status <= ${status.max}',
            ),
            ?mediaTypeGuard,
          ],
        );
      case DefaultResponseStatus():
        return _caseWithGuards(
          'case (_, $contentTypePattern)',
          [?mediaTypeGuard],
        );
    }
  }

  Code _caseWithGuards(String pattern, List<Code> guards) {
    if (guards.isEmpty) return Code('$pattern:');

    return Block.of([
      Code('$pattern when '),
      for (final (index, guard) in guards.indexed) ...[
        if (index > 0) const Code(' && '),
        guard,
      ],
      const Code(':'),
    ]);
  }

  Code _mediaTypeRangeGuard(String mediaTypeRange) {
    return Block.of([
      refer(
        'matchesMediaTypeRange',
        'package:tonik_util/tonik_util.dart',
      ).code,
      const Code(r'(_$mediaType, '),
      Code(specLiteralStringCode(mediaTypeRange)),
      const Code(')'),
    ]);
  }

  Code _caseBody(
    Operation operation,
    ResponseStatus status,
    ResponseObject response,
    String? contentType,
  ) {
    // Multipart response decoding is not supported; generate a runtime error.
    if (_isMultipartResponseBody(response, contentType)) {
      return generateResponseDecodingExceptionExpression(
        'Multipart response body decoding is not supported.',
      ).statement;
    }

    if (operation.responses.length > 1) {
      return _generateMultiResponseCase(
        operation,
        status,
        response,
        contentType,
      );
    } else {
      return _generateSingleResponseCase(response, contentType);
    }
  }

  bool _isMultipartResponseBody(
    ResponseObject response,
    String? contentType,
  ) {
    final responseBody = contentType != null
        ? response.bodies.firstWhere(
            (body) => body.rawContentType == contentType,
            orElse: () => response.bodies.first,
          )
        : response.bodies.firstOrNull;

    return responseBody?.contentType == ContentType.multipart;
  }

  ({List<Code> statements, String? varName})? _createBodyDecode(
    ResponseObject response,
    String? contentType,
  ) {
    final hasBody = response.bodyCount > 0;
    if (!hasBody) return null;

    final responseBody = contentType != null
        ? response.bodies.firstWhere(
            (body) => body.rawContentType == contentType,
            orElse: () => response.bodies.first,
          )
        : response.bodies.firstOrNull;

    if (responseBody == null) return null;

    final contentTypeEnum = responseBody.contentType;

    return switch (contentTypeEnum) {
      ContentType.json => _createJsonBodyDecode(responseBody),
      ContentType.text => _createTextBodyDecode(),
      ContentType.bytes => _createBytesBodyDecode(),
      ContentType.form => _createFormBodyDecode(responseBody),
      ContentType.multipart => (
        statements: [
          generateResponseDecodingExceptionExpression(
            'Multipart response body decoding is not supported.',
          ).statement,
        ],
        varName: r'_$body',
      ),
    };
  }

  ({List<Code> statements, String? varName}) _createJsonBodyDecode(
    ResponseBody responseBody,
  ) {
    if (_isJsonBodyPureThrow(responseBody.model)) {
      return (
        statements: [
          generateJsonDecodingExceptionExpression(
            _neverPureThrowMessage(responseBody.model),
          ).statement,
        ],
        varName: null,
      );
    }

    final statements = <Code>[];
    const jsonVar = r'_$json';
    const bodyVar = r'_$body';

    statements.add(
      declareFinal(jsonVar)
          .assign(
            refer(
              'decodeResponseJson',
              'package:tonik_util/tonik_util.dart',
            ).call(
              [refer('response.data')],
              {},
              [refer('Object?', 'dart:core')],
            ),
          )
          .statement,
    );

    final helperContext = InlineHelperContext(nameManager: nameManager);
    final built = buildFromJsonValueExpression(
      jsonVar,
      model: responseBody.model,
      nameManager: nameManager,
      package: package,
      helperContext: helperContext,
      useImmutableCollections: useImmutableCollections,
    );
    statements
      ..addAll(spliceInlineHelpers(built.inlineFunctions))
      ..add(declareFinal(bodyVar).assign(built.unsafeRawBody).statement);

    return (statements: statements, varName: bodyVar);
  }

  ({List<Code> statements, String varName}) _createTextBodyDecode() {
    const bodyVar = r'_$body';
    return (
      statements: [
        declareFinal(bodyVar)
            .assign(
              refer(
                'decodeResponseText',
                'package:tonik_util/tonik_util.dart',
              ).call([refer('response.data')]),
            )
            .statement,
      ],
      varName: bodyVar,
    );
  }

  ({List<Code> statements, String varName}) _createBytesBodyDecode() {
    const bodyVar = r'_$body';
    return (
      statements: [
        declareFinal(bodyVar)
            .assign(
              refer(
                'TonikFileBytes',
                'package:tonik_util/tonik_util.dart',
              ).call([
                refer(
                  'decodeResponseBytes',
                  'package:tonik_util/tonik_util.dart',
                ).call([refer('response.data')]),
              ]),
            )
            .statement,
      ],
      varName: bodyVar,
    );
  }

  ({List<Code> statements, String? varName}) _createFormBodyDecode(
    ResponseBody responseBody,
  ) {
    if (_isFormBodyPureThrow(responseBody.model)) {
      return (
        statements: [
          generateFormDecodingExceptionExpression(
            _neverPureThrowMessage(responseBody.model),
          ).statement,
        ],
        varName: null,
      );
    }

    final statements = <Code>[];
    const formStringVar = r'_$formString';
    const bodyVar = r'_$body';

    statements.add(
      declareFinal(formStringVar)
          .assign(
            refer(
              'decodeResponseText',
              'package:tonik_util/tonik_util.dart',
            ).call([refer('response.data')]),
          )
          .statement,
    );

    final bodyBuilt = buildFromFormValueExpression(
      refer(formStringVar),
      model: responseBody.model,
      isRequired: true,
      nameManager: nameManager,
      package: package,
      explode: literalTrue,
      useImmutableCollections: useImmutableCollections,
    );
    statements
      ..addAll(spliceInlineHelpers(bodyBuilt.inlineFunctions))
      ..add(declareFinal(bodyVar).assign(bodyBuilt.unsafeRawBody).statement);

    return (statements: statements, varName: bodyVar);
  }

  // Mirrors the non-nullable `NeverModel` arm in
  // buildFromJsonValueExpression, which emits a bare throw. Nullable models
  // reference `_$json` in their null guard and must not short-circuit here.
  bool _isJsonBodyPureThrow(Model model, {bool isNullable = false}) {
    final nullable = isNullable || model.isEffectivelyNullable;
    switch (model) {
      case NeverModel():
        return !nullable;
      case AliasModel():
        return _isJsonBodyPureThrow(model.model, isNullable: nullable);
      default:
        return false;
    }
  }

  // A bare `NeverModel` collapses to a pure throw regardless of nullability,
  // because `_$formString` comes from `decodeResponseText` and is typed
  // `String` (non-null).
  bool _isFormBodyPureThrow(Model model) {
    switch (model) {
      case NeverModel():
        return true;
      case AliasModel():
        return _isFormBodyPureThrow(model.model);
      default:
        return false;
    }
  }

  String _neverPureThrowMessage(Model model) {
    final resolved = model is AliasModel ? model.resolved : model;
    if (resolved is ListModel) {
      return 'Cannot decode List<NeverModel> - this type does not permit '
          'any value.';
    }
    return 'Cannot decode NeverModel - this type does not permit any value.';
  }

  Code _generateMultiResponseCase(
    Operation operation,
    ResponseStatus status,
    ResponseObject response,
    String? contentType,
  ) {
    final wrapperName = nameManager.responseWrapperNames(operation).$2[status]!;
    final wrapperBaseName = nameManager.responseWrapperNames(operation).$1;
    final wrapperUrl = sourceFileUrl(
      package,
      'response_wrapper',
      wrapperBaseName,
    );
    final bodyDecode = _createBodyDecode(response, contentType);

    if (response.hasHeaders || response.bodyCount > 1) {
      return _generateMultiResponseWithHeaders(
        wrapperName,
        wrapperUrl,
        response,
        contentType,
        bodyDecode,
      );
    } else if (bodyDecode != null) {
      return _generateMultiResponseWithBody(
        wrapperName,
        wrapperUrl,
        bodyDecode,
      );
    } else {
      return refer(wrapperName, wrapperUrl).call([]).returned.statement;
    }
  }

  Code _generateSingleResponseCase(
    ResponseObject response,
    String? contentType,
  ) {
    final bodyDecode = _createBodyDecode(response, contentType);

    if (response.hasHeaders || response.bodyCount > 1) {
      return _generateSingleResponseWithHeaders(
        response,
        contentType,
        bodyDecode,
      );
    } else if (bodyDecode != null) {
      if (bodyDecode.varName == null) {
        return Block.of(bodyDecode.statements);
      }
      return Block.of([
        ...bodyDecode.statements,
        refer(bodyDecode.varName!).returned.statement,
      ]);
    } else {
      return const Code('return;');
    }
  }

  Code _generateMultiResponseWithHeaders(
    String wrapperName,
    String wrapperUrl,
    ResponseObject response,
    String? contentType,
    ({List<Code> statements, String? varName})? bodyDecode,
  ) {
    final headerResult = _decodeHeaders(response);

    if (headerResult.unsupported.isNotEmpty) {
      final unsupported = headerResult.unsupported.first;
      return generateSimpleDecodingExceptionExpression(
        '${unsupported.reason} at ${unsupported.headerName}',
      ).statement;
    }

    if (bodyDecode != null && bodyDecode.varName == null) {
      // Pure-throw body: no wrapper or response object is constructed, so
      // typed-header decode expressions are intentionally omitted from the
      // emitted block — only never-header existence checks run before the
      // throw. Raw headers remain available to callers via
      // TonikError.response.headers.
      return Block.of([
        ..._generateNeverHeaderChecks(headerResult.neverHeaders),
        ...bodyDecode.statements,
      ]);
    }

    final responseArgs = <String, Expression>{};
    if (bodyDecode != null) {
      responseArgs['body'] = refer(bodyDecode.varName!);
    }
    responseArgs.addAll(headerResult.supported);

    final responseBaseName = nameManager.responseNames(response).baseName;
    final responseUrl = sourceFileUrl(package, 'response', responseBaseName);
    final wrapperArgs = <String, Expression>{
      'body': refer(
        contentType != null && response.bodyCount > 1
            ? nameManager
                  .responseNames(response)
                  .implementationNames[contentType]!
            : responseBaseName,
        responseUrl,
      ).call([], responseArgs),
    };

    return Block.of([
      ..._generateNeverHeaderChecks(headerResult.neverHeaders),
      if (bodyDecode != null) ...bodyDecode.statements,
      refer(wrapperName, wrapperUrl).call([], wrapperArgs).returned.statement,
    ]);
  }

  Code _generateMultiResponseWithBody(
    String wrapperName,
    String wrapperUrl,
    ({List<Code> statements, String? varName}) bodyDecode,
  ) {
    if (bodyDecode.varName == null) {
      return Block.of(bodyDecode.statements);
    }
    return Block.of([
      ...bodyDecode.statements,
      refer(
        wrapperName,
        wrapperUrl,
      ).call([], {'body': refer(bodyDecode.varName!)}).returned.statement,
    ]);
  }

  Code _generateSingleResponseWithHeaders(
    ResponseObject response,
    String? contentType,
    ({List<Code> statements, String? varName})? bodyDecode,
  ) {
    final headerResult = _decodeHeaders(response);

    if (headerResult.unsupported.isNotEmpty) {
      final unsupported = headerResult.unsupported.first;
      return generateSimpleDecodingExceptionExpression(
        '${unsupported.reason} at ${unsupported.headerName}',
      ).statement;
    }

    if (bodyDecode != null && bodyDecode.varName == null) {
      // Pure-throw body: no wrapper or response object is constructed, so
      // typed-header decode expressions are intentionally omitted from the
      // emitted block — only never-header existence checks run before the
      // throw. Raw headers remain available to callers via
      // TonikError.response.headers.
      return Block.of([
        ..._generateNeverHeaderChecks(headerResult.neverHeaders),
        ...bodyDecode.statements,
      ]);
    }

    final args = <String, Expression>{};
    if (bodyDecode != null) {
      args['body'] = refer(bodyDecode.varName!);
    }
    args.addAll(headerResult.supported);

    final responseBaseName = nameManager.responseNames(response).baseName;
    final responseUrl = sourceFileUrl(package, 'response', responseBaseName);
    return Block.of([
      ..._generateNeverHeaderChecks(headerResult.neverHeaders),
      if (bodyDecode != null) ...bodyDecode.statements,
      refer(
        contentType != null && response.bodyCount > 1
            ? nameManager
                  .responseNames(response)
                  .implementationNames[contentType]!
            : responseBaseName,
        responseUrl,
      ).call([], args).returned.statement,
    ]);
  }

  List<Code> _generateNeverHeaderChecks(List<String> neverHeaders) {
    return neverHeaders.map((headerName) {
      final headerValue = refer('response')
          .property('headers')
          .property('value')
          .call([specLiteralString(headerName)]);
      return Block.of([
        const Code('if ('),
        headerValue.code,
        const Code(' != null) {'),
        generateSimpleDecodingExceptionExpression(
          'NeverModel does not permit any value at $headerName',
          raw: true,
        ).statement,
        const Code('}'),
      ]);
    }).toList();
  }

  ({
    Map<String, Expression> supported,
    List<({String headerName, String reason})> unsupported,
    List<String> neverHeaders,
  })
  _decodeHeaders(ResponseObject response) {
    final supported = <String, Expression>{};
    final unsupported = <({String headerName, String reason})>[];
    final neverHeaders = <String>[];
    final normalizedProperties = normalizeResponseProperties(response);
    final normalizedHeaders = normalizedProperties.where(
      (norm) => norm.header != null,
    );

    for (final norm in normalizedHeaders) {
      final rawHeaderName = response.headers.entries
          .firstWhere((entry) => entry.value == norm.header)
          .key;

      if (norm.property.model is NeverModel) {
        neverHeaders.add(rawHeaderName);
        continue;
      }

      final normalizedName = norm.normalizedName;
      final unsupportedReason = getSimpleDecodingUnsupportedReason(
        norm.property.model,
      );

      if (unsupportedReason != null) {
        unsupported.add((headerName: rawHeaderName, reason: unsupportedReason));
        continue;
      }

      final headerValue = refer('response')
          .property('headers')
          .property('value')
          .call([specLiteralString(rawHeaderName)]);
      final resolvedHeader = norm.header!.resolve();
      final decode = buildSimpleValueExpression(
        headerValue,
        model: norm.property.model,
        isRequired: norm.property.isRequired,
        nameManager: nameManager,
        package: package,
        contextProperty: rawHeaderName,
        explode: literalBool(resolvedHeader.explode),
      );
      supported[normalizedName] = decode.expression;
    }
    return (
      supported: supported,
      unsupported: unsupported,
      neverHeaders: neverHeaders,
    );
  }

  Set<String?> _getContentTypes(Response response) {
    final contentTypes = <String?>{};
    final resolvedResponse = response.resolved;
    final keptByNormalized = <String, ResponseBody>{};
    final droppedByNormalized = <String, List<ResponseBody>>{};

    for (final body in resolvedResponse.bodies) {
      final raw = body.rawContentType;
      final normalized = tonik_util.extractMediaType(raw);
      if (normalized == null) {
        contentTypes.add(raw);
        continue;
      }
      if (!keptByNormalized.containsKey(normalized)) {
        keptByNormalized[normalized] = body;
        contentTypes.add(raw);
      } else {
        droppedByNormalized.putIfAbsent(normalized, () => []).add(body);
      }
    }

    if (contentTypes.isEmpty) {
      contentTypes.add(null);
    }

    for (final entry in droppedByNormalized.entries) {
      final kept = keptByNormalized[entry.key]!;
      final dropped = entry.value;
      final droppedRaws = dropped
          .map((b) => '"${b.rawContentType}"')
          .join(', ');

      final keptType = kept.model.runtimeType;
      final hasDistinctModels = dropped.any(
        (b) => b.model.runtimeType != keptType,
      );

      final modelInfo = hasDistinctModels
          ? ' kept model: $keptType; dropped models: '
                '${dropped.map((b) => b.model.runtimeType).join(', ')}.'
          : '';

      log.warning(
        'Multiple response content types normalize to '
        '"${entry.key}"; keeping the first raw entry and dropping '
        '$droppedRaws. '
        'The dropped entries are unreachable at runtime.$modelInfo',
      );
    }

    return _sortContentTypesBySpecificity(contentTypes);
  }

  Set<String?> _sortContentTypesBySpecificity(Set<String?> contentTypes) {
    final exact = <String?>[];
    final typeRanges = <String?>[];
    final catchAllRanges = <String?>[];
    final catchAllPatterns = <String?>[];

    for (final contentType in contentTypes) {
      switch (_contentTypeSpecificity(contentType)) {
        case 0:
          exact.add(contentType);
        case 1:
          typeRanges.add(contentType);
        case 2:
          catchAllRanges.add(contentType);
        case 3:
          catchAllPatterns.add(contentType);
      }
    }

    return {
      ...exact,
      ...typeRanges,
      ...catchAllRanges,
      ...catchAllPatterns,
    };
  }

  int _contentTypeSpecificity(String? contentType) {
    final normalized = tonik_util.extractMediaType(contentType);
    if (normalized == null) return 3;
    if (normalized == '*/*') return 2;
    if (_isTypeMediaRange(normalized)) return 1;
    return 0;
  }

  bool _isMediaTypeRange(String mediaType) {
    return mediaType == '*/*' || _isTypeMediaRange(mediaType);
  }

  bool _isTypeMediaRange(String mediaType) {
    final slashIndex = mediaType.indexOf('/');
    if (slashIndex <= 0 || slashIndex == mediaType.length - 1) return false;

    final type = mediaType.substring(0, slashIndex);
    final subtype = mediaType.substring(slashIndex + 1);
    return subtype == '*' && type != '*' && !type.contains('*');
  }
}
