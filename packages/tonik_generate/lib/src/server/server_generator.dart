import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
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

    final library = Library((b) => b..body.addAll(classes));

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
    final serverClasses =
        servers.map((server) {
          final serverName = names.serverMap[server]!;
          return _generateServerClass(serverName, names.baseName, server);
        }).toList();

    final customServerClass = _generateCustomServerClass(
      names.customName,
      names.baseName,
    );

    return [baseClass, ...serverClasses, customServerClass];
  }

  Class _generateBaseClass(String className) {
    final dioType = refer('Dio', 'package:dio/dio.dart');
    final dioNullableType = refer('Dio?', 'package:dio/dio.dart');

    return Class(
      (b) =>
          b
            ..name = className
            ..abstract = true
            ..sealed = true
            ..fields.addAll([
              Field(
                (f) =>
                    f
                      ..name = 'baseUrl'
                      ..type = refer('String', 'dart:core')
                      ..modifier = FieldModifier.final$,
              ),
              Field(
                (f) =>
                    f
                      ..name = 'serverConfig'
                      ..type = refer(
                        'ServerConfig',
                        'package:tonik_util/tonik_util.dart',
                      )
                      ..modifier = FieldModifier.final$,
              ),
              Field(
                (f) =>
                    f
                      ..name = '_dio'
                      ..type = dioNullableType,
              ),
            ])
            ..constructors.add(
              Constructor(
                (c) =>
                    c
                      ..optionalParameters.addAll([
                        Parameter(
                          (p) =>
                              p
                                ..name = 'baseUrl'
                                ..named = true
                                ..required = true
                                ..toThis = true,
                        ),
                        Parameter(
                          (p) =>
                              p
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
                (m) =>
                    m
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

    return Class(
      (b) =>
          b
            ..name = className
            ..extend = refer(baseClassName)
            ..docs.add('/// ${server.description ?? 'Server'} - ${server.url}')
            ..constructors.add(
              Constructor(
                (c) =>
                    c
                      ..optionalParameters.add(
                        Parameter(
                          (p) =>
                              p
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

  Class _generateCustomServerClass(String className, String baseClassName) {
    final serverConfigType = refer(
      'ServerConfig',
      'package:tonik_util/tonik_util.dart',
    );

    return Class(
      (b) =>
          b
            ..name = className
            ..extend = refer(baseClassName)
            ..docs.add('/// Custom server with user-defined base URL')
            ..constructors.add(
              Constructor(
                (c) =>
                    c
                      ..optionalParameters.addAll([
                        Parameter(
                          (p) =>
                              p
                                ..name = 'baseUrl'
                                ..named = true
                                ..required = true
                                ..toSuper = true,
                        ),
                        Parameter(
                          (p) =>
                              p
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
