import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';

/// Generates server classes for API client.
class ServerGenerator {
  /// Creates a new ServerGenerator.
  const ServerGenerator({required this.nameManager});

  /// The name manager to use for name generation.
  final NameManager nameManager;

  /// Generates server classes for the given servers.
  ({String code, String filename}) generate(List<Server> servers) {
    final classes = generateClasses(servers);
    final enums = generateEnums(servers);

    final library = Library((b) => b..body.addAll([...enums, ...classes]));

    final allocator = CorePrefixedAllocator();
    final emitter = DartEmitter(
      allocator: allocator,
      useNullSafetySyntax: true,
      orderDirectives: true,
    );
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final names = nameManager.serverNames(servers);
    final code = formatter.formatWithHeader('${library.accept(emitter)}');
    return (code: code, filename: '${names.baseName.toSnakeCase()}.dart');
  }

  /// Generates the classes for testing purposes.
  @visibleForTesting
  List<Class> generateClasses(List<Server> servers) {
    final names = nameManager.serverNames(servers);
    final baseClass = _generateBaseClass(names.baseName);
    final serverClasses = servers.map((server) {
      final serverName = names.serverMap[server]!;
      return _generateServerClass(serverName, names.baseName, server);
    }).toList();

    final customServerClass = _generateCustomServerClass(
      names.customName,
      names.baseName,
    );

    return [baseClass, ...serverClasses, customServerClass];
  }

  /// Generates enums for server variables with constrained values.
  @visibleForTesting
  List<Enum> generateEnums(List<Server> servers) {
    final names = nameManager.serverNames(servers);
    final enums = <Enum>[];

    for (final server in servers) {
      final serverName = names.serverMap[server]!;
      for (final variable in server.variables) {
        if (variable.enumValues != null && variable.enumValues!.isNotEmpty) {
          enums.add(_generateVariableEnum(serverName, variable));
        }
      }
    }

    return enums;
  }

  Enum _generateVariableEnum(String serverName, ServerVariable variable) {
    final enumName = nameManager.serverVariableEnumName(serverName, variable);
    final normalizedValues = normalizeEnumValues(variable.enumValues!);

    return Enum(
      (b) => b
        ..name = enumName
        ..docs.add('/// Allowed values for the ${variable.name} variable.')
        ..fields.add(
          Field(
            (f) => f
              ..name = 'value'
              ..type = refer('String', 'dart:core')
              ..modifier = FieldModifier.final$,
          ),
        )
        ..constructors.add(
          Constructor(
            (c) => c
              ..constant = true
              ..requiredParameters.add(
                Parameter(
                  (p) => p
                    ..name = 'value'
                    ..toThis = true,
                ),
              ),
          ),
        )
        ..values.addAll(
          normalizedValues.map(
            (normalized) => EnumValue(
              (v) => v
                ..name = normalized.normalizedName
                ..arguments.add(literalString(normalized.originalValue)),
            ),
          ),
        ),
    );
  }

  /// Returns the normalized enum value name for the given value.
  @visibleForTesting
  String getNormalizedEnumValueName(ServerVariable variable, String value) {
    final normalizedValues = normalizeEnumValues(variable.enumValues!);
    return normalizedValues
        .firstWhere((n) => n.originalValue == value)
        .normalizedName;
  }

  Class _generateBaseClass(String className) {
    final dioType = refer('Dio', 'package:dio/dio.dart');
    final dioNullableType = refer('Dio?', 'package:dio/dio.dart');

    return Class(
      (b) => b
        ..name = className
        ..abstract = true
        ..sealed = true
        ..fields.addAll([
          Field(
            (f) => f
              ..name = 'baseUrl'
              ..type = refer('String', 'dart:core')
              ..modifier = FieldModifier.final$,
          ),
          Field(
            (f) => f
              ..name = 'serverConfig'
              ..type = refer(
                'ServerConfig',
                'package:tonik_util/tonik_util.dart',
              )
              ..modifier = FieldModifier.final$,
          ),
          Field(
            (f) => f
              ..name = '_dio'
              ..type = dioNullableType,
          ),
        ])
        ..constructors.add(
          Constructor(
            (c) => c
              ..optionalParameters.addAll([
                Parameter(
                  (p) => p
                    ..name = 'baseUrl'
                    ..named = true
                    ..required = true
                    ..toThis = true,
                ),
                Parameter(
                  (p) => p
                    ..name = 'serverConfig'
                    ..named = true
                    ..required = true
                    ..toThis = true,
                ),
              ]),
          ),
        )
        ..methods.add(
          Method(
            (m) => m
              ..name = 'dio'
              ..type = MethodType.getter
              ..returns = dioType
              ..body = Block.of([
                const Code('if (_dio == null) {'),
                Code.scope((a) => '  _dio = ${a(dioType)}();'),
                const Code(
                  '  serverConfig.configureDio(_dio!, baseUrl);',
                ),
                const Code('}'),
                const Code('return _dio!;'),
              ]),
          ),
        ),
    );
  }

  Class _generateServerClass(
    String className,
    String baseClassName,
    Server server,
  ) {
    final serverConfigType = refer(
      'ServerConfig',
      'package:tonik_util/tonik_util.dart',
    );

    final hasVariables = server.variables.isNotEmpty;

    if (!hasVariables) {
      return _generateStaticServerClass(
        className,
        baseClassName,
        server,
        serverConfigType,
      );
    }

    return _generateTemplatedServerClass(
      className,
      baseClassName,
      server,
      serverConfigType,
    );
  }

  Class _generateStaticServerClass(
    String className,
    String baseClassName,
    Server server,
    Reference serverConfigType,
  ) {
    return Class(
      (b) => b
        ..name = className
        ..extend = refer(baseClassName)
        ..docs.add('/// ${server.description ?? 'Server'} - ${server.url}')
        ..constructors.add(
          Constructor(
            (c) => c
              ..optionalParameters.add(
                Parameter(
                  (p) => p
                    ..name = 'serverConfig'
                    ..named = true
                    ..defaultTo = Code.scope(
                      (a) => 'const ${a(serverConfigType)}()',
                    )
                    ..toSuper = true,
                ),
              )
              ..initializers.add(
                Code("super(baseUrl: '${server.url}')"),
              ),
          ),
        ),
    );
  }

  Class _generateTemplatedServerClass(
    String className,
    String baseClassName,
    Server server,
    Reference serverConfigType,
  ) {
    final variableParams = <Parameter>[];
    final variableFields = <Field>[];

    for (final variable in server.variables) {
      final hasEnum =
          variable.enumValues != null && variable.enumValues!.isNotEmpty;

      if (hasEnum) {
        final enumName = nameManager.serverVariableEnumName(
          className,
          variable,
        );
        final defaultEnumValue = getNormalizedEnumValueName(
          variable,
          variable.defaultValue,
        );

        variableParams.add(
          Parameter(
            (p) => p
              ..name = variable.name
              ..named = true
              ..toThis = true
              ..defaultTo = Code('$enumName.$defaultEnumValue'),
          ),
        );

        variableFields.add(
          Field(
            (f) => f
              ..name = variable.name
              ..type = refer(enumName)
              ..modifier = FieldModifier.final$,
          ),
        );
      } else {
        variableParams.add(
          Parameter(
            (p) => p
              ..name = variable.name
              ..named = true
              ..toThis = true
              ..defaultTo = literalString(variable.defaultValue).code,
          ),
        );

        variableFields.add(
          Field(
            (f) => f
              ..name = variable.name
              ..type = refer('String', 'dart:core')
              ..modifier = FieldModifier.final$,
          ),
        );
      }
    }

    // Add serverConfig parameter last.
    variableParams.add(
      Parameter(
        (p) => p
          ..name = 'serverConfig'
          ..named = true
          ..defaultTo = Code.scope(
            (a) => 'const ${a(serverConfigType)}()',
          )
          ..toSuper = true,
      ),
    );

    // Build URL expression with variable substitution.
    final urlExpression = _buildUrlExpression(server.url, server.variables);

    return Class(
      (b) => b
        ..name = className
        ..extend = refer(baseClassName)
        ..docs.add('/// ${server.description ?? 'Server'} - ${server.url}')
        ..fields.addAll(variableFields)
        ..constructors.add(
          Constructor(
            (c) => c
              ..optionalParameters.addAll(variableParams)
              ..initializers.add(
                Code('super(baseUrl: $urlExpression)'),
              ),
          ),
        ),
    );
  }

  String _buildUrlExpression(
    String urlTemplate,
    List<ServerVariable> variables,
  ) {
    var result = urlTemplate;

    for (final variable in variables) {
      final hasEnum =
          variable.enumValues != null && variable.enumValues!.isNotEmpty;
      final replacement = hasEnum
          ? '\${${variable.name}.value}'
          : '\${${variable.name}}';

      result = result.replaceAll('{${variable.name}}', replacement);
    }

    return "'$result'";
  }

  Class _generateCustomServerClass(String className, String baseClassName) {
    final serverConfigType = refer(
      'ServerConfig',
      'package:tonik_util/tonik_util.dart',
    );

    return Class(
      (b) => b
        ..name = className
        ..extend = refer(baseClassName)
        ..docs.add('/// Custom server with user-defined base URL')
        ..constructors.add(
          Constructor(
            (c) => c
              ..optionalParameters.addAll([
                Parameter(
                  (p) => p
                    ..name = 'baseUrl'
                    ..named = true
                    ..required = true
                    ..toSuper = true,
                ),
                Parameter(
                  (p) => p
                    ..name = 'serverConfig'
                    ..named = true
                    ..defaultTo = Code.scope(
                      (a) => 'const ${a(serverConfigType)}()',
                    )
                    ..toSuper = true,
                ),
              ]),
          ),
        ),
    );
  }
}
