import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/file_name.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';
import 'package:tonik_generate/src/util/example_doc_formatter.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';
import 'package:tonik_generate/src/util/operation_parameter_generator.dart';
import 'package:tonik_generate/src/util/response_type_generator.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';

/// Generator for creating API client classes from Operation definitions.
class ApiClientGenerator {
  ApiClientGenerator({
    required this.nameManager,
    required this.package,
    required this.defaultsCache,
    this.useImmutableCollections = false,
  });

  final NameManager nameManager;
  final String package;
  final OperationDefaultsCache defaultsCache;
  final bool useImmutableCollections;

  ({String code, String filename}) generate(
    Set<Operation> operations,
    Tag tag,
    List<Server> servers,
  ) {
    final className = nameManager.tagName(tag);
    final fileName = fileNameForClass(className);

    final library = Library(
      (b) => b..body.add(generateClass(operations, tag, servers)),
    );

    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: fileName);
  }

  /// Generates the API client class.
  @visibleForTesting
  Class generateClass(
    Set<Operation> operations,
    Tag tag,
    List<Server> servers,
  ) {
    final serverNames = nameManager.serverNames(servers);
    final serverBaseClassName = serverNames.baseName;

    final operationFields = operations.map((operation) {
      final operationName = nameManager.operationName(operation);
      final fieldName = '_${operationName.toCamelCase()}';
      final operationUrl = sourceFileUrl(package, 'operation', operationName);

      return Field(
        (b) => b
          ..name = fieldName
          ..modifier = FieldModifier.final$
          ..type = refer(operationName, operationUrl),
      );
    }).toList();

    final constructorInitializers = operations.map((operation) {
      final operationName = nameManager.operationName(operation);
      final fieldName = '_${operationName.toCamelCase()}';
      final operationUrl = sourceFileUrl(package, 'operation', operationName);

      return refer(fieldName)
          .assign(
            refer(operationName, operationUrl).call([refer('server.dio')]),
          )
          .code;
    }).toList();

    return Class(
      (b) => b
        ..name = nameManager.tagName(tag)
        ..fields.addAll(operationFields)
        ..docs.addAll(formatDocComment(tag.description))
        ..constructors.add(
          Constructor(
            (b) => b
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'server'
                    ..type = refer(
                      serverBaseClassName,
                      sourceFileUrl(package, 'server', serverBaseClassName),
                    ),
                ),
              )
              ..initializers.addAll(constructorInitializers),
          ),
        )
        ..methods.addAll(operations.map(_generateMethod)),
    );
  }

  /// Generates a method for an operation.
  Method _generateMethod(Operation operation) {
    final hasRequestBody =
        operation.requestBody?.resolvedContent.isNotEmpty ?? false;

    final normalizedParams = normalizeRequestParameters(
      pathParameters: operation.pathParameters.map((p) => p.resolve()).toSet(),
      queryParameters: operation.queryParameters
          .map((p) => p.resolve())
          .toSet(),
      headers: operation.headers.map((p) => p.resolve()).toSet(),
      cookieParameters: operation.cookieParameters
          .map((p) => p.resolve())
          .toSet(),
      reservedNames: operationReservedParameterNames(
        hasRequestBody: hasRequestBody,
      ),
    );

    final operationClassName = nameManager.operationName(operation);
    final defaults = defaultsCache.forOperation(
      operation,
      normalizedParams: normalizedParams,
      operationClassName: operationClassName,
      initialReservedNames: initialOperationDefaultReservedNames(
        normalizedParams: normalizedParams,
        hasRequestBody: hasRequestBody,
      ),
    );

    final operationUrl = sourceFileUrl(
      package,
      'operation',
      operationClassName,
    );
    final qualifiedDefaults = {
      for (final entry in defaults.byName.entries)
        entry.key: entry.value.withOwner(
          className: operationClassName,
          url: operationUrl,
        ),
    };

    final parameters = generateParameters(
      operation: operation,
      nameManager: nameManager,
      package: package,
      defaultsByName: qualifiedDefaults,
    );

    final resultType = resultTypeForOperation(
      operation,
      nameManager,
      package,
      useImmutableCollections: useImmutableCollections,
    );
    final operationFieldName =
        '_${nameManager.operationName(operation).toCamelCase()}';

    final requiredParams = parameters.where((p) => p.required).toList();
    final optionalParams = parameters.where((p) => !p.required).toList();

    final paramMap = {
      for (final param in parameters) param.name: refer(param.name),
    };

    final docs = formatDocComments([operation.summary, operation.description]);

    if (operation.securitySchemes.isNotEmpty) {
      docs
        ..add('///')
        ..add('/// Security:');
      for (final scheme in operation.securitySchemes) {
        final schemeInfo = _formatSecuritySchemeForMethod(scheme);
        docs.addAll(schemeInfo);
      }
    }

    final paramDocs = _generateParameterDocs(operation, nameManager);
    if (paramDocs.isNotEmpty) {
      docs.addAll(paramDocs);
    }

    final paramExampleDocs = _generateParameterExampleDocs(operation);
    if (paramExampleDocs.isNotEmpty) {
      docs
        ..add('///')
        ..add('/// Parameter examples:')
        ..addAll(paramExampleDocs);
    }

    final requestBody = operation.requestBody;
    if (requestBody != null) {
      for (final content in requestBody.resolvedContent) {
        final exampleDocs = formatExamplesAsDocs(content.examples);
        if (exampleDocs.isEmpty) continue;
        docs
          ..add('///')
          ..add('/// Request body (${content.rawContentType}):')
          ..addAll(exampleDocs);
      }
    }

    final sortedResponses = operation.responses.entries.toList()
      ..sort(_compareResponses);
    for (final entry in sortedResponses) {
      final resolved = entry.value.resolved;
      for (final body in resolved.bodies) {
        final exampleDocs = formatExamplesAsDocs(body.examples);
        if (exampleDocs.isEmpty) continue;
        docs
          ..add('///')
          ..add(
            '/// Response ${_formatStatus(entry.key)} '
            '(${body.rawContentType}):',
          )
          ..addAll(exampleDocs);
      }
    }

    return Method(
      (b) {
        b
          ..name = nameManager.operationMethodName(operation)
          ..returns = TypeReference(
            (b) => b
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(resultType),
          )
          ..docs.addAll(docs);

        if (operation.isDeprecated) {
          b.annotations.add(
            refer('Deprecated', 'dart:core').call([
              literalString('This operation is deprecated.'),
            ]),
          );
        }

        b
          ..optionalParameters.addAll([
            ...requiredParams.map((p) => p.rebuild((b) => b..named = true)),
            ...optionalParams.map((p) => p.rebuild((b) => b..named = true)),
          ])
          ..modifier = MethodModifier.async
          ..lambda = true
          ..body = refer(operationFieldName).call([], paramMap).code;
      },
    );
  }

  /// Formats security scheme information for method documentation
  List<String> _formatSecuritySchemeForMethod(SecurityScheme scheme) {
    final lines = <String>[];

    switch (scheme) {
      case ApiKeySecurityScheme():
        final location = switch (scheme.location) {
          ApiKeyLocation.header => 'header',
          ApiKeyLocation.query => 'query',
          ApiKeyLocation.cookie => 'cookie',
        };
        if (scheme.description != null && scheme.description!.isNotEmpty) {
          lines.addAll(
            formatDocCommentWithPrefix(
              '- API Key ($location): ',
              scheme.description,
            ),
          );
        } else {
          lines.add('/// - API Key ($location)');
        }

      case HttpSecurityScheme():
        final schemeName = switch (scheme.scheme.toLowerCase()) {
          'bearer' => 'Bearer',
          'basic' => 'Basic',
          _ => scheme.scheme.toUpperCase(),
        };
        if (scheme.description != null && scheme.description!.isNotEmpty) {
          lines.addAll(
            formatDocCommentWithPrefix(
              '- HTTP $schemeName: ',
              scheme.description,
            ),
          );
        } else {
          lines.add('/// - HTTP $schemeName');
        }

      case OAuth2SecurityScheme():
        if (scheme.description != null && scheme.description!.isNotEmpty) {
          lines.addAll(
            formatDocCommentWithPrefix('- OAuth2: ', scheme.description),
          );
        } else {
          lines.add('/// - OAuth2');
        }
        final flows = scheme.flows;

        // Method docs show one OAuth2 flow to keep scope details compact.
        OAuth2Flow? activeFlow;
        if (flows.authorizationCode != null) {
          activeFlow = flows.authorizationCode;
        } else if (flows.implicit != null) {
          activeFlow = flows.implicit;
        } else if (flows.clientCredentials != null) {
          activeFlow = flows.clientCredentials;
        } else if (flows.password != null) {
          activeFlow = flows.password;
        }

        if (activeFlow != null && activeFlow.scopes.isNotEmpty) {
          lines.add(
            '///   Required scopes: ${activeFlow.scopes.keys.join(', ')}',
          );
        }

      case OpenIdConnectSecurityScheme():
        if (scheme.description != null && scheme.description!.isNotEmpty) {
          lines.addAll(
            formatDocCommentWithPrefix(
              '- OpenID Connect: ',
              scheme.description,
            ),
          );
        } else {
          lines.add('/// - OpenID Connect');
        }
        lines.add('///   Discovery URL: ${scheme.openIdConnectUrl}');

      case MutualTlsSecurityScheme():
        if (scheme.description != null && scheme.description!.isNotEmpty) {
          lines.addAll(
            formatDocCommentWithPrefix('- Mutual TLS: ', scheme.description),
          );
        } else {
          lines.add('/// - Mutual TLS');
        }
    }

    return lines;
  }

  /// Generates documentation for operation parameters.
  ///
  /// For alias parameters, uses the override description if present,
  /// otherwise falls back to the resolved parameter's description.
  List<String> _generateParameterDocs(
    Operation operation,
    NameManager nameManager,
  ) {
    final docs = <String>[];

    final hasRequestBody =
        operation.requestBody?.resolvedContent.isNotEmpty ?? false;

    final normalizedParams = normalizeRequestParameters(
      pathParameters: operation.pathParameters.map((p) => p.resolve()).toSet(),
      queryParameters: operation.queryParameters
          .map((p) => p.resolve())
          .toSet(),
      headers: operation.headers.map((p) => p.resolve()).toSet(),
      cookieParameters: operation.cookieParameters
          .map((p) => p.resolve())
          .toSet(),
      reservedNames: operationReservedParameterNames(
        hasRequestBody: hasRequestBody,
      ),
    );

    final paramDescriptionsByOriginalName = <String, String>{};

    for (final param in operation.pathParameters) {
      final description = _getPathParameterDescription(param);
      if (description != null && description.isNotEmpty) {
        final resolvedParam = param.resolve();
        final name = resolvedParam.name;
        if (name != null) {
          paramDescriptionsByOriginalName[name] = description;
        }
      }
    }

    for (final param in operation.queryParameters) {
      final description = _getQueryParameterDescription(param);
      if (description != null && description.isNotEmpty) {
        final resolvedParam = param.resolve();
        final name = resolvedParam.name;
        if (name != null) {
          paramDescriptionsByOriginalName[name] = description;
        }
      }
    }

    for (final param in operation.headers) {
      final description = _getHeaderDescription(param);
      if (description != null && description.isNotEmpty) {
        final resolvedParam = param.resolve();
        final name = resolvedParam.name;
        if (name != null) {
          paramDescriptionsByOriginalName[name] = description;
        }
      }
    }

    for (final param in operation.cookieParameters) {
      final description = switch (param) {
        CookieParameterAlias(:final description, :final parameter) =>
          description ?? _getCookieParameterDescription(parameter),
        CookieParameterObject(:final description) => description,
      };
      if (description != null && description.isNotEmpty) {
        final resolvedParam = param.resolve();
        final name = resolvedParam.name;
        if (name != null) {
          paramDescriptionsByOriginalName[name] = description;
        }
      }
    }

    for (final pathParam in normalizedParams.pathParameters) {
      final description =
          paramDescriptionsByOriginalName[pathParam.parameter.name];
      if (description != null && description.isNotEmpty) {
        docs.addAll(
          formatDocCommentWithPrefix(
            '[${pathParam.normalizedName}] ',
            description,
          ),
        );
      }
    }

    for (final queryParam in normalizedParams.queryParameters) {
      final description =
          paramDescriptionsByOriginalName[queryParam.parameter.name];
      if (description != null && description.isNotEmpty) {
        docs.addAll(
          formatDocCommentWithPrefix(
            '[${queryParam.normalizedName}] ',
            description,
          ),
        );
      }
    }

    for (final headerParam in normalizedParams.headers) {
      final description =
          paramDescriptionsByOriginalName[headerParam.parameter.name];
      if (description != null && description.isNotEmpty) {
        docs.addAll(
          formatDocCommentWithPrefix(
            '[${headerParam.normalizedName}] ',
            description,
          ),
        );
      }
    }

    for (final cookieParam in normalizedParams.cookieParameters) {
      final description =
          paramDescriptionsByOriginalName[cookieParam.parameter.name];
      if (description != null && description.isNotEmpty) {
        docs.addAll(
          formatDocCommentWithPrefix(
            '[${cookieParam.normalizedName}] ',
            description,
          ),
        );
      }
    }

    return docs;
  }

  List<String> _generateParameterExampleDocs(Operation operation) {
    final hasRequestBody =
        operation.requestBody?.resolvedContent.isNotEmpty ?? false;

    final normalizedParams = normalizeRequestParameters(
      pathParameters: operation.pathParameters.map((p) => p.resolve()).toSet(),
      queryParameters: operation.queryParameters
          .map((p) => p.resolve())
          .toSet(),
      headers: operation.headers.map((p) => p.resolve()).toSet(),
      cookieParameters: operation.cookieParameters
          .map((p) => p.resolve())
          .toSet(),
      reservedNames: operationReservedParameterNames(
        hasRequestBody: hasRequestBody,
      ),
    );

    final paramExamplesByOriginalName = <String, List<Example>>{};
    for (final param in operation.pathParameters) {
      final resolved = param.resolve();
      if (resolved.examples.isNotEmpty && resolved.name != null) {
        paramExamplesByOriginalName[resolved.name!] = resolved.examples;
      }
    }
    for (final param in operation.queryParameters) {
      final resolved = param.resolve();
      if (resolved.examples.isNotEmpty && resolved.name != null) {
        paramExamplesByOriginalName[resolved.name!] = resolved.examples;
      }
    }
    for (final param in operation.headers) {
      final resolved = param.resolve();
      if (resolved.examples.isNotEmpty && resolved.name != null) {
        paramExamplesByOriginalName[resolved.name!] = resolved.examples;
      }
    }
    for (final param in operation.cookieParameters) {
      final resolved = param.resolve();
      if (resolved.examples.isNotEmpty && resolved.name != null) {
        paramExamplesByOriginalName[resolved.name!] = resolved.examples;
      }
    }

    final result = <String>[];
    var first = true;
    void appendIfExamples(String? originalName, String normalizedName) {
      if (originalName == null) return;
      final examples = paramExamplesByOriginalName[originalName];
      if (examples == null || examples.isEmpty) return;
      final exampleDocs = formatExamplesAsDocs(examples);
      if (exampleDocs.isEmpty) return;
      if (!first) result.add('///');
      first = false;
      result
        ..add('/// [$normalizedName]:')
        ..addAll(exampleDocs);
    }

    for (final p in normalizedParams.pathParameters) {
      appendIfExamples(p.parameter.name, p.normalizedName);
    }
    for (final p in normalizedParams.queryParameters) {
      appendIfExamples(p.parameter.name, p.normalizedName);
    }
    for (final p in normalizedParams.headers) {
      appendIfExamples(p.parameter.name, p.normalizedName);
    }
    for (final p in normalizedParams.cookieParameters) {
      appendIfExamples(p.parameter.name, p.normalizedName);
    }
    return result;
  }

  String? _getPathParameterDescription(PathParameter param) {
    return switch (param) {
      PathParameterAlias(:final description, :final parameter) =>
        description ?? _getPathParameterDescription(parameter),
      PathParameterObject(:final description) => description,
    };
  }

  String? _getQueryParameterDescription(QueryParameter param) {
    return switch (param) {
      QueryParameterAlias(:final description, :final parameter) =>
        description ?? _getQueryParameterDescription(parameter),
      QueryParameterObject(:final description) => description,
    };
  }

  String? _getHeaderDescription(RequestHeader param) {
    return switch (param) {
      RequestHeaderAlias(:final description, :final header) =>
        description ?? _getHeaderDescription(header),
      RequestHeaderObject(:final description) => description,
    };
  }

  String? _getCookieParameterDescription(CookieParameter param) {
    return switch (param) {
      CookieParameterAlias(:final description, :final parameter) =>
        description ?? _getCookieParameterDescription(parameter),
      CookieParameterObject(:final description) => description,
    };
  }

  String _formatStatus(ResponseStatus status) => switch (status) {
    ExplicitResponseStatus(:final statusCode) => '$statusCode',
    RangeResponseStatus(:final min, :final max) => '$min–$max',
    DefaultResponseStatus() => 'default',
  };

  int _compareResponses(
    MapEntry<ResponseStatus, Response> a,
    MapEntry<ResponseStatus, Response> b,
  ) {
    final aDefault = a.key is DefaultResponseStatus;
    final bDefault = b.key is DefaultResponseStatus;
    if (aDefault != bDefault) return aDefault ? 1 : -1;
    return _numericStart(a.key).compareTo(_numericStart(b.key));
  }

  int _numericStart(ResponseStatus status) => switch (status) {
    ExplicitResponseStatus(:final statusCode) => statusCode,
    RangeResponseStatus(:final min) => min,
    DefaultResponseStatus() => 0,
  };
}
