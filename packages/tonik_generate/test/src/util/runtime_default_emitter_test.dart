import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/default_resolution.dart';

void main() {
  late Context context;
  late NameManager nameManager;
  const package = 'example';
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  setUp(() {
    context = Context.initial();
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
  });

  String renderGetter(Method getter) {
    final cls = Class(
      (b) => b
        ..name = '_Holder'
        ..methods.add(getter),
    );
    final source = cls.accept(DartEmitter()).toString();
    return formatter.format(source);
  }

  String formatBody(String body) =>
      formatter.format('class _Holder { $body }');

  RuntimeResolvedDefault? resolve({
    required String name,
    required Model model,
    required Object? raw,
    String container = 'Holder',
    bool isNullableOverride = false,
    bool useImmutableCollections = false,
    Set<String>? reservedSeed,
  }) {
    return resolveRuntimeDefault(
      normalizedName: name,
      model: model,
      rawDefault: raw,
      containerName: container,
      reservedNames: reservedSeed ?? <String>{name},
      nameManager: nameManager,
      package: package,
      isNullableOverride: isNullableOverride,
      useImmutableCollections: useImmutableCollections,
    );
  }

  group('resolveRuntimeDefault — non-const leaf primitives', () {
    test('DateTime leaf with string default emits decodeJsonDateTime '
        'getter', () {
      final result = resolve(
        name: 'startsAt',
        model: DateTimeModel(context: context),
        raw: '2024-01-01T00:00:00Z',
      );

      expect(result, isNotNull);
      expect(result!.memberName, 'startsAtDefault');
      expect(result.type.symbol, 'DateTime');
      expect(result.getter.static, isTrue);
      expect(result.getter.type, MethodType.getter);
      expect(result.getter.lambda, isTrue);
      expect(result.getter.name, 'startsAtDefault');

      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static DateTime get startsAtDefault => r'2024-01-01T00:00:00Z'
    .decodeJsonDateTime(context: r'Holder.startsAt');
''',
          ),
        ),
      );
    });

    test('Uri leaf with string default emits decodeJsonUri getter', () {
      final result = resolve(
        name: 'homepage',
        model: UriModel(context: context),
        raw: 'https://example.com',
      );

      expect(result, isNotNull);
      expect(result!.type.symbol, 'Uri');
      expect(result.getter.lambda, isTrue);
      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static Uri get homepageDefault => r'https://example.com'
    .decodeJsonUri(context: r'Holder.homepage');
''',
          ),
        ),
      );
    });

    test('Decimal leaf emits decodeJsonBigDecimal getter', () {
      final result = resolve(
        name: 'amount',
        model: DecimalModel(context: context),
        raw: '9.99',
      );

      expect(result, isNotNull);
      expect(result!.getter.lambda, isTrue);
      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static BigDecimal get amountDefault => r'9.99'
    .decodeJsonBigDecimal(context: r'Holder.amount');
''',
          ),
        ),
      );
    });

    test('Binary leaf wraps decoder in TonikFileBytes', () {
      final result = resolve(
        name: 'payload',
        model: BinaryModel(context: context),
        raw: 'base64-blob',
      );

      expect(result, isNotNull);
      expect(result!.getter.lambda, isTrue);
      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static TonikFile get payloadDefault => TonikFileBytes(
  r'base64-blob'.decodeJsonBinary(context: r'Holder.payload'),
);
''',
          ),
        ),
      );
    });

    test('Base64 leaf wraps decoder in TonikFileBytes', () {
      final result = resolve(
        name: 'token',
        model: Base64Model(context: context),
        raw: 'aGVsbG8=',
      );

      expect(result, isNotNull);
      expect(result!.getter.lambda, isTrue);
      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static TonikFile get tokenDefault => TonikFileBytes(
  r'aGVsbG8='.decodeJsonBase64(context: r'Holder.token'),
);
''',
          ),
        ),
      );
    });
  });

  group('resolveRuntimeDefault — composite targets', () {
    test('plain ClassModel with nested object default calls fromJson', () {
      final pricing = ClassModel(
        isDeprecated: false,
        name: 'Pricing',
        properties: [
          Property(
            name: 'amount',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'currency',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = resolve(
        name: 'pricing',
        model: pricing,
        raw: const <String, Object?>{'amount': '9.99', 'currency': 'USD'},
      );

      expect(result, isNotNull);
      expect(result!.type.symbol, 'Pricing');
      expect(result.getter.lambda, isTrue);
      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static Pricing get pricingDefault => Pricing.fromJson(
  const <String, Object?>{r'amount': r'9.99', r'currency': r'USD'},
);
''',
          ),
        ),
      );
    });

    test('OneOf composite default delegates to wrapper.fromJson', () {
      final cat = ClassModel(
        isDeprecated: false,
        name: 'Cat',
        properties: const [],
        context: context,
        examples: const [],
      );
      final dog = ClassModel(
        isDeprecated: false,
        name: 'Dog',
        properties: const [],
        context: context,
        examples: const [],
      );
      final pet = OneOfModel(
        isDeprecated: false,
        name: 'Pet',
        models: {
          (discriminatorValue: 'cat', model: cat),
          (discriminatorValue: 'dog', model: dog),
        },
        discriminator: 'kind',
        context: context,
        examples: const [],
      );

      final result = resolve(
        name: 'pet',
        model: pet,
        raw: const <String, Object?>{'kind': 'cat', 'livesLeft': 9},
      );

      expect(result, isNotNull);
      expect(result!.type.symbol, 'Pet');
      expect(result.getter.lambda, isTrue);
      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static Pet get petDefault => Pet.fromJson(
  const <String, Object?>{r'kind': r'cat', r'livesLeft': 9},
);
''',
          ),
        ),
      );
    });

    test('AllOf composite default delegates to wrapper.fromJson', () {
      final left = ClassModel(
        isDeprecated: false,
        name: 'Left',
        properties: const [],
        context: context,
        examples: const [],
      );
      final right = ClassModel(
        isDeprecated: false,
        name: 'Right',
        properties: const [],
        context: context,
        examples: const [],
      );
      final merged = AllOfModel(
        isDeprecated: false,
        name: 'Merged',
        models: {left, right},
        context: context,
        examples: const [],
      );

      final result = resolve(
        name: 'merged',
        model: merged,
        raw: const <String, Object?>{'a': 1, 'b': 'two'},
      );

      expect(result, isNotNull);
      expect(result!.type.symbol, 'Merged');
      expect(result.getter.lambda, isTrue);
      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static Merged get mergedDefault => Merged.fromJson(
  const <String, Object?>{r'a': 1, r'b': r'two'},
);
''',
          ),
        ),
      );
    });

    test('AnyOf composite default delegates to wrapper.fromJson', () {
      final left = ClassModel(
        isDeprecated: false,
        name: 'Alpha',
        properties: const [],
        context: context,
        examples: const [],
      );
      final right = ClassModel(
        isDeprecated: false,
        name: 'Beta',
        properties: const [],
        context: context,
        examples: const [],
      );
      final any = AnyOfModel(
        isDeprecated: false,
        name: 'Either',
        models: {
          (discriminatorValue: null, model: left),
          (discriminatorValue: null, model: right),
        },
        context: context,
        examples: const [],
      );

      final result = resolve(
        name: 'either',
        model: any,
        raw: const <String, Object?>{'tag': 'alpha'},
      );

      expect(result, isNotNull);
      expect(result!.type.symbol, 'Either');
      expect(result.getter.lambda, isTrue);
      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static Either get eitherDefault => Either.fromJson(
  const <String, Object?>{r'tag': r'alpha'},
);
''',
          ),
        ),
      );
    });

    test('recursive class default emits a fromJson call without a cycle guard',
        () {
      final recursive = ClassModel(
        isDeprecated: false,
        name: 'Node',
        properties: <Property>[],
        context: context,
        examples: const [],
      );
      // Self-reference: `next: Node?`. The runtime emitter must dispatch to
      // `Node.fromJson(...)` without recursing into the property tree —
      // otherwise materialisation would loop forever on cyclic models.
      recursive.properties.add(
        Property(
          name: 'next',
          model: recursive,
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      );

      final result = resolve(
        name: 'next',
        model: recursive,
        raw: const <String, Object?>{},
      );

      expect(result, isNotNull);
      expect(result!.type.symbol, 'Node');
      expect(result.getter.lambda, isTrue);
      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static Node get nextDefault =>
    Node.fromJson(const <String, Object?>{});
''',
          ),
        ),
      );
    });

    test('ClassModel with additionalProperties decodes via fromJson', () {
      final bag = ClassModel(
        isDeprecated: false,
        name: 'Bag',
        properties: [
          Property(
            name: 'known',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        additionalProperties: const UnrestrictedAdditionalProperties(),
        context: context,
        examples: const [],
      );

      final result = resolve(
        name: 'bag',
        model: bag,
        raw: const <String, Object?>{
          'known': 'k',
          'extra': 1,
          'flag': true,
          'list': <Object?>[1, 'two'],
        },
      );

      expect(result, isNotNull);
      expect(result!.type.symbol, 'Bag');
      expect(result.getter.lambda, isTrue);
      expect(
        collapseWhitespace(renderGetter(result.getter)),
        collapseWhitespace(
          formatBody(
            '''
static Bag get bagDefault => Bag.fromJson(
  const <String, Object?>{
    r'known': r'k',
    r'extra': 1,
    r'flag': true,
    r'list': <Object?>[1, r'two'],
  },
);
''',
          ),
        ),
      );
    });
  });

  group('resolveRuntimeDefault — semantics', () {
    test('null raw default short-circuits to null without consuming a '
        'name', () {
      final reserved = <String>{'startsAt'};
      final result = resolveRuntimeDefault(
        normalizedName: 'startsAt',
        model: DateTimeModel(context: context),
        rawDefault: null,
        containerName: 'Holder',
        reservedNames: reserved,
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
      expect(reserved, {'startsAt'});
    });

    test('name collision against an existing reserved name appends a suffix',
        () {
      final reserved = <String>{'startsAt', 'startsAtDefault'};
      final result = resolveRuntimeDefault(
        normalizedName: 'startsAt',
        model: DateTimeModel(context: context),
        rawDefault: '2024-01-01T00:00:00Z',
        containerName: 'Holder',
        reservedNames: reserved,
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(result!.memberName, 'startsAtDefault2');
      expect(reserved.contains('startsAtDefault2'), isTrue);
    });

    test(
      'computed getter is static, lambda, and not const — no cache field, '
      'no late modifier',
      () {
        final result = resolve(
          name: 'startsAt',
          model: DateTimeModel(context: context),
          raw: '2024-01-01T00:00:00Z',
        );

        expect(result, isNotNull);
        expect(result!.getter.type, MethodType.getter);
        expect(result.getter.lambda, isTrue);
        expect(result.getter.static, isTrue);
      },
    );

    test(
      'implausible default emits without warning — runtime FormatException',
      () {
        // DateTime field with a non-string default. The runtime fallback
        // emits the getter unchecked; the runtime decoder is the validator.
        final result = resolve(
          name: 'startsAt',
          model: DateTimeModel(context: context),
          raw: 42,
        );

        expect(result, isNotNull);
        expect(
          collapseWhitespace(renderGetter(result!.getter)),
          collapseWhitespace(
            formatBody(
              '''
static DateTime get startsAtDefault =>
    42.decodeJsonDateTime(context: r'Holder.startsAt');
''',
            ),
          ),
        );
      },
    );

    test(
      'non-JSON-encodable raw default (e.g. a YAML-parsed DateTime) returns '
      'null AND logs a warning identifying the property and the rejected '
      'runtime type — so the silently-dropped default is observable',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'DefaultResolution',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final yamlDateTime = DateTime.utc(2024, 6, 15);
        final result = resolve(
          name: 'startsAt',
          model: DateTimeModel(context: context),
          raw: yamlDateTime,
        );

        expect(result, isNull);
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        final message = warnings.single.message;
        expect(message, contains('Holder.startsAt'));
        expect(message, contains('DateTime'));
        expect(message, contains('not JSON-encodable'));
      },
    );
  });
}
