import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/operation_parameter_generator.dart';
import 'package:tonik_generate/src/util/response_type_generator.dart';

/// Generator for creating API client classes from Operation definitions.
class ApiClientGenerator {
  ApiClientGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(
    Set<Operation> operations,
    Tag tag,
    List<Server> servers,
  ) {
    final className = nameManager.tagName(tag);
    final fileNameSnakeCase = className.toSnakeCase();
    final fileName = '$fileNameSnakeCase.dart';

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

  /// Generates the API client class
  @visibleForTesting
  Class generateClass(
    Set<Operation> operations,
    Tag tag,
    List<Server> servers,
  ) {
    // Get the server base class name
    final serverNames = nameManager.serverNames(servers);
    final serverBaseClassName = serverNames.baseName;

    // Create private fields for each operation
    final operationFields = operations.map((operation) {
      final operationName = nameManager.operationName(operation);
      final fieldName = '_${operationName.toCamelCase()}';

      return Field(
        (b) => b
          ..name = fieldName
          ..modifier = FieldModifier.final$
          ..type = refer(operationName, package),
      );
    }).toList();

    // Create constructor initializers for each operation
    final constructorInitializers = operations.map((operation) {
      final operationName = nameManager.operationName(operation);
      final fieldName = '_${operationName.toCamelCase()}';

      return refer(
        fieldName,
      ).assign(refer(operationName, package).call([refer('server.dio')])).code;
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
                    ..type = refer(serverBaseClassName, package),
                ),
              )
              ..initializers.addAll(constructorInitializers),
          ),
        )
        ..methods.addAll(operations.map(_generateMethod)),
    );
  }

  /// Generates a method for an operation
  Method _generateMethod(Operation operation) {
    final parameters = generateParameters(
      operation: operation,
      nameManager: nameManager,
      package: package,
    );

    final resultType = resultTypeForOperation(operation, nameManager, package);
    final operationFieldName =
        '_${nameManager.operationName(operation).toCamelCase()}';

    final requiredParams = parameters.where((p) => p.required).toList();
    final optionalParams = parameters.where((p) => !p.required).toList();

    final paramMap = {
      for (final param in parameters) param.name: refer(param.name),
    };

    final docs = formatDocComments([operation.summary, operation.description]);

    // Add security information to documentation
    if (operation.securitySchemes.isNotEmpty) {
      docs
        ..add('///')
        ..add('/// Security:');
      for (final scheme in operation.securitySchemes) {
        final schemeInfo = _formatSecuritySchemeForMethod(scheme);
        docs.addAll(schemeInfo);
      }
    }

    // Add parameter descriptions to documentation
    final paramDocs = _generateParameterDocs(operation, nameManager);
    if (paramDocs.isNotEmpty) {
      docs.addAll(paramDocs);
    }

    return Method(
      (b) {
        b
          ..name = nameManager.operationName(operation).toCamelCase()
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
        final description = (scheme.description?.isNotEmpty ?? false)
            ? ': ${scheme.description}'
            : '';
        lines.add('/// - API Key ($location)$description');

      case HttpSecurityScheme():
        final schemeName = switch (scheme.scheme.toLowerCase()) {
          'bearer' => 'Bearer',
          'basic' => 'Basic',
          _ => scheme.scheme.toUpperCase(),
        };
        final description = (scheme.description?.isNotEmpty ?? false)
            ? ': ${scheme.description}'
            : '';
        lines.add('/// - HTTP $schemeName$description');

      case OAuth2SecurityScheme():
        final description = (scheme.description?.isNotEmpty ?? false)
            ? ': ${scheme.description}'
            : '';
        lines.add('/// - OAuth2$description');
        final flows = scheme.flows;

        // Find the first available flow and show its scopes
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
        final description = (scheme.description?.isNotEmpty ?? false)
            ? ': ${scheme.description}'
            : '';
        lines.add('/// - OpenID Connect$description');
        lines.add('///   Discovery URL: ${scheme.openIdConnectUrl}');

      case MutualTlsSecurityScheme():
        final description = (scheme.description?.isNotEmpty ?? false)
            ? ': ${scheme.description}'
            : '';
        lines.add('/// - Mutual TLS$description');
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

    final normalizedParams = normalizeRequestParameters(
      pathParameters: operation.pathParameters.map((p) => p.resolve()).toSet(),
      queryParameters: operation.queryParameters
          .map((p) => p.resolve())
          .toSet(),
      headers: operation.headers.map((p) => p.resolve()).toSet(),
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

    for (final pathParam in normalizedParams.pathParameters) {
      final description =
          paramDescriptionsByOriginalName[pathParam.parameter.name];
      if (description != null && description.isNotEmpty) {
        docs.add('/// [${pathParam.normalizedName}] $description');
      }
    }

    for (final queryParam in normalizedParams.queryParameters) {
      final description =
          paramDescriptionsByOriginalName[queryParam.parameter.name];
      if (description != null && description.isNotEmpty) {
        docs.add('/// [${queryParam.normalizedName}] $description');
      }
    }

    for (final headerParam in normalizedParams.headers) {
      final description =
          paramDescriptionsByOriginalName[headerParam.parameter.name];
      if (description != null && description.isNotEmpty) {
        docs.add('/// [${headerParam.normalizedName}] $description');
      }
    }

    return docs;
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
}
