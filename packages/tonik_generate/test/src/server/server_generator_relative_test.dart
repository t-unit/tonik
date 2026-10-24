import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/server/server_generator.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';

void main() {
  late ServerGenerator generator;
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    generator = ServerGenerator(
      nameManager: NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      ),
      backendGenerator: const DioBackendGenerator(),
    );
  });

  test('static relative constructor requires a Uri origin', () {
    final serverClass = generator.generateClasses(const [
      Server(url: '/relative/api', description: null, variables: []),
    ])[1];
    final origin = serverClass.constructors.single.optionalParameters
        .firstWhere((parameter) => parameter.name == 'origin');

    expect(origin.required, isTrue);
    expect(origin.named, isTrue);
    expect(origin.type?.symbol, 'Uri');
    expect(origin.type?.url, 'dart:core');
    expect(
      collapseWhitespace(format(serverClass.accept(emitter).toString())),
      collapseWhitespace(
        format("""
        /// Server - /relative/api
        class AnonymousServer extends Server {
          AnonymousServer({
            super.serverConfig = const ServerConfig<Dio>(),
            required Uri origin,
          }) : super(baseUrl: origin.resolve(r'/relative/api').toString());
        }
      """),
      ),
    );
  });

  test('relative variables cannot shadow the origin parameter', () {
    final serverClass = generator.generateClasses(const [
      Server(
        url: '/{origin}',
        description: null,
        variables: [
          ServerVariable(
            name: 'origin',
            defaultValue: 'api',
            enumValues: null,
            description: null,
          ),
        ],
      ),
    ])[1];

    expect(
      collapseWhitespace(format(serverClass.accept(emitter).toString())),
      collapseWhitespace(
        format(r"""
        /// Server - /{origin}
        class AnonymousServer extends Server {
          AnonymousServer({
            required Uri origin,
            this.$origin = r'api',
            super.serverConfig = const ServerConfig<Dio>(),
          }) : super(baseUrl: origin.resolve(r'/' '${$origin}').toString());

          final String $origin;
        }
      """),
      ),
    );
  });

  test('absolute scheme variables keep existing constructor parameters', () {
    final serverClass = generator.generateClasses(const [
      Server(
        url: '{scheme}://example.com/{origin}',
        description: null,
        variables: [
          ServerVariable(
            name: 'scheme',
            defaultValue: 'https',
            enumValues: null,
            description: null,
          ),
          ServerVariable(
            name: 'origin',
            defaultValue: 'api',
            enumValues: null,
            description: null,
          ),
        ],
      ),
    ])[1];

    expect(
      serverClass.constructors.single.optionalParameters.map((p) => p.name),
      ['scheme', 'origin', 'serverConfig'],
    );
    final origin = serverClass.constructors.single.optionalParameters[1];
    expect(origin.required, isFalse);
    expect(origin.toThis, isTrue);
  });

  test('network-relative URLs require an origin', () {
    final serverClass = generator.generateClasses(const [
      Server(url: '//example.com/api', description: null, variables: []),
    ])[1];

    final origin = serverClass.constructors.single.optionalParameters
        .firstWhere((parameter) => parameter.name == 'origin');
    expect(origin.required, isTrue);
  });

  test('empty URLs resolve against the origin', () {
    final serverClass = generator.generateClasses(const [
      Server(url: '', description: null, variables: []),
    ])[1];

    expect(
      collapseWhitespace(format(serverClass.accept(emitter).toString())),
      collapseWhitespace(
        format("""
        /// Server -
        class AnonymousServer extends Server {
          AnonymousServer({
            super.serverConfig = const ServerConfig<Dio>(),
            required Uri origin,
          }) : super(baseUrl: origin.resolve(r'').toString());
        }
      """),
      ),
    );
  });
}
