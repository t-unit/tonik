import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/response/response_generator.dart';
import 'package:tonik_generate/src/transport/http_backend_generator.dart';

void main() {
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );
  late ResponseGenerator generator;
  late Context context;

  setUp(() {
    context = Context.initial();
    generator = ResponseGenerator(
      nameManager: NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      ),
      package: 'api',
    );
  });

  test('unconstrained stream copyWith keeps the outer stream nonnullable', () {
    final response = ResponseObject(
      name: 'Items',
      context: context,
      description: '',
      headers: const {},
      bodies: {
        ResponseBody(
          model: AnyModel(context: context),
          rawContentType: 'application/x-ndjson',
          contentType: ContentType.bytes,
          examples: const [],
          delivery: ResponseDelivery.ndjson,
        ),
      },
    );
    final generated = generator.generateResponseClass(response);
    expect(
      generated.fields.single.type!.accept(emitter).toString(),
      'Stream<TonikResult<Object?,Response<Object?>>>',
    );
    final copyWith = generated.methods.singleWhere((m) => m.name == 'copyWith');
    expect(
      collapseWhitespace(formatter.format(copyWith.accept(emitter).toString())),
      collapseWhitespace(
        formatter.format('''
        Items Function({Stream<TonikResult<Object?,Response<Object?>>>? body}) get copyWith {
          return ({Stream<TonikResult<Object?,Response<Object?>>>? body}) => Items(body: body ?? this.body);
        }
      '''),
      ),
    );
    expect(
      generated.constructors.single.optionalParameters.single.toThis,
      isTrue,
    );
    expect(
      generated.constructors.single.optionalParameters.single.required,
      isTrue,
    );
  });

  test('streamed list equality and hash use the stream identity', () {
    final response = ResponseObject(
      name: 'Lists',
      context: context,
      description: '',
      headers: const {},
      bodies: {
        ResponseBody(
          model: ListModel(
            content: IntegerModel(context: context),
            context: context,
            examples: const [],
          ),
          rawContentType: 'application/x-ndjson',
          contentType: ContentType.bytes,
          examples: const [],
          delivery: ResponseDelivery.ndjson,
        ),
      },
    );
    final generated = generator.generateResponseClass(response);
    final equality = generated.methods.singleWhere(
      (m) => m.name == 'operator ==',
    );
    final hash = generated.methods.singleWhere((m) => m.name == 'hashCode');
    expect(
      collapseWhitespace(
        formatter.format('class Lists { ${equality.accept(emitter)} }'),
      ),
      collapseWhitespace(
        formatter.format('''
        class Lists {
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is Lists && other.body == this.body;
        }
        }
      '''),
      ),
    );
    expect(
      collapseWhitespace(
        formatter.format('class Lists { ${hash.accept(emitter)}; }'),
      ),
      collapseWhitespace(
        formatter.format('''
        class Lists {
        @override
        int get hashCode => body.hashCode;
        }
      '''),
      ),
    );
  });

  test(
    'HTTP media variants retain nullable item results and native metadata',
    () {
      generator = ResponseGenerator(
        nameManager: generator.nameManager,
        package: 'api',
        backendGenerator: const HttpBackendGenerator(),
      );
      final response = ResponseObject(
        name: 'Mixed',
        context: context,
        description: '',
        headers: {
          'X-Count': ResponseHeaderObject(
            name: 'X-Count',
            context: context,
            description: '',
            model: IntegerModel(context: context),
            isRequired: true,
            isDeprecated: false,
            explode: false,
            encoding: ResponseHeaderEncoding.simple,
            examples: const [],
          ),
        },
        bodies: {
          ResponseBody(
            model: StringModel(context: context),
            rawContentType: 'application/json',
            contentType: ContentType.json,
            examples: const [],
          ),
          ResponseBody(
            model: AliasModel(
              model: IntegerModel(context: context),
              context: context,
              examples: const [],
              defaultValue: null,
              isNullable: true,
            ),
            rawContentType: 'application/x-ndjson',
            contentType: ContentType.bytes,
            examples: const [],
            delivery: ResponseDelivery.ndjson,
          ),
        },
      );
      final generated = generator.generateMultiBodyResponseClasses(response);
      final complete = generated[1] as Class;
      final stream = generated[2] as Class;
      expect(complete.fields.single.type!.accept(emitter).toString(), 'String');
      expect(
        stream.fields.single.type!.accept(emitter).toString(),
        'Stream<TonikResult<int?,BaseResponse>>',
      );
      final copyWith = stream.methods.singleWhere((m) => m.name == 'copyWith');
      final type = copyWith.returns! as FunctionType;
      expect(
        type.namedParameters['body']!.accept(emitter).toString(),
        'Stream<TonikResult<int?,BaseResponse>>?',
      );
      expect(
        type.namedParameters['xCount']!.accept(emitter).toString(),
        'int?',
      );
      expect(stream.constructors.single.optionalParameters.last.toThis, isTrue);
      expect(
        stream.constructors.single.optionalParameters.last.required,
        isTrue,
      );
    },
  );
}
