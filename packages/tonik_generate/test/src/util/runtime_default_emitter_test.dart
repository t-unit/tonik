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
    final source = cls
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    return formatter.format(source);
  }

  String formatBody(String body) =>
      formatter.format('class _Holder { $body }');

  group('resolveRuntimeDefault — non-const leaf primitives', () {
    test('DateTime leaf with string default emits decodeJsonDateTime '
        'getter', () {
      final result = resolveRuntimeDefault(
        normalizedName: 'startsAt',
        specName: 'startsAt',
        model: DateTimeModel(context: context),
        rawDefault: '2024-01-01T00:00:00Z',
        containerName: 'Holder',
        location: 'property',
        reservedNames: <String>{'startsAt'},
        nameManager: nameManager,
        package: package,
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

    test('Binary leaf wraps decoder in TonikFileBytes', () {
      final result = resolveRuntimeDefault(
        normalizedName: 'payload',
        specName: 'payload',
        model: BinaryModel(context: context),
        rawDefault: 'base64-blob',
        containerName: 'Holder',
        location: 'property',
        reservedNames: <String>{'payload'},
        nameManager: nameManager,
        package: package,
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

      final result = resolveRuntimeDefault(
        normalizedName: 'pricing',
        specName: 'pricing',
        model: pricing,
        rawDefault: const <String, Object?>{
          'amount': '9.99',
          'currency': 'USD',
        },
        containerName: 'Holder',
        location: 'property',
        reservedNames: <String>{'pricing'},
        nameManager: nameManager,
        package: package,
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

    test(
      'self-referential MapModel default emits a block body with inline '
      'helper declarations spliced before the return statement',
      () {
        final tree = MapModel(
          name: 'Tree',
          valueModel: AnyModel(context: context),
          context: context,
          examples: const [],
        );
        tree.valueModel = tree;

        final result = resolveRuntimeDefault(
          normalizedName: 'tree',
          specName: 'tree',
          model: tree,
          rawDefault: const <String, Object?>{},
          containerName: 'Holder',
          location: 'property',
          reservedNames: <String>{'tree'},
          nameManager: nameManager,
          package: package,
        );

        expect(result, isNotNull);
        expect(result!.type.symbol, 'Tree');
        expect(
          result.getter.lambda,
          isNot(isTrue),
          reason:
              'self-referential typedefs require an inline helper '
              'declaration, which cannot live in a lambda body',
        );
        expect(
          collapseWhitespace(renderGetter(result.getter)),
          collapseWhitespace(
            formatBody(
              r'''
static Tree get treeDefault {
  late final Tree Function(Object?) _$decodeTree;
  _$decodeTree = (Object? v) => v.decodeJsonMap(
    (v) => _$decodeTree(v),
    context: r"Tree (at 'Holder.tree')",
  );
  return _$decodeTree(const <String, Object?>{});
}
''',
            ),
          ),
        );
      },
    );

    test('recursive class default emits a fromJson call without a cycle guard',
        () {
      final recursive = ClassModel(
        isDeprecated: false,
        name: 'Node',
        properties: <Property>[],
        context: context,
        examples: const [],
      );
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

      final result = resolveRuntimeDefault(
        normalizedName: 'next',
        specName: 'next',
        model: recursive,
        rawDefault: const <String, Object?>{},
        containerName: 'Holder',
        location: 'property',
        reservedNames: <String>{'next'},
        nameManager: nameManager,
        package: package,
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

  });

  group('resolveRuntimeDefault — collections with non-const leaves', () {
    test(
      'ListModel<DateTime> default decodes each element on the const list '
      'literal via the receiverOverride plumbing',
      () {
        final dateList = ListModel(
          content: DateTimeModel(context: context),
          context: context,
          examples: const [],
        );

        final result = resolveRuntimeDefault(
          normalizedName: 'windows',
          specName: 'windows',
          model: dateList,
          rawDefault: const <Object?>[
            '2024-01-01T00:00:00Z',
            '2024-06-15T12:00:00Z',
          ],
          containerName: 'Holder',
          location: 'property',
          reservedNames: <String>{'windows'},
          nameManager: nameManager,
          package: package,
        );

        expect(result, isNotNull);
        expect(result!.type.symbol, 'List');
        expect(result.getter.lambda, isTrue);
        expect(
          collapseWhitespace(renderGetter(result.getter)),
          collapseWhitespace(
            formatBody(
              '''
static List<DateTime> get windowsDefault =>
    const <Object?>[r'2024-01-01T00:00:00Z', r'2024-06-15T12:00:00Z']
        .decodeJsonList<String>(context: r'Holder.windows')
        .map((e) => e.decodeJsonDateTime(context: r'Holder.windows'))
        .toList();
''',
            ),
          ),
        );
      },
    );

    test(
      'useImmutableCollections: true wraps the decoded ListModel in IList',
      () {
        final dateList = ListModel(
          content: DateTimeModel(context: context),
          context: context,
          examples: const [],
        );

        final result = resolveRuntimeDefault(
          normalizedName: 'windows',
          specName: 'windows',
          model: dateList,
          rawDefault: const <Object?>['2024-01-01T00:00:00Z'],
          containerName: 'Holder',
          location: 'property',
          reservedNames: <String>{'windows'},
          nameManager: nameManager,
          package: package,
          useImmutableCollections: true,
        );

        expect(result, isNotNull);
        expect(result!.type.symbol, 'IList');
        expect(result.getter.lambda, isTrue);
        expect(
          collapseWhitespace(renderGetter(result.getter)),
          collapseWhitespace(
            formatBody(
              '''
static IList<DateTime> get windowsDefault => IList(
  const <Object?>[r'2024-01-01T00:00:00Z']
      .decodeJsonList<String>(context: r'Holder.windows')
      .map((e) => e.decodeJsonDateTime(context: r'Holder.windows'))
      .toList(),
);
''',
            ),
          ),
        );
      },
    );

  });

  group('resolveRuntimeDefault — isNullableOverride: true', () {
    test(
      'nullable DateTime leaf decodes the const literal via the non-nullable '
      'decoder; the return type still carries the nullable suffix because '
      'the field/parameter is nullable but the raw literal is statically '
      'non-null',
      () {
        final result = resolveRuntimeDefault(
          normalizedName: 'startsAt',
          specName: 'startsAt',
          model: DateTimeModel(context: context),
          rawDefault: '2024-01-01T00:00:00Z',
          containerName: 'Holder',
          location: 'property',
          reservedNames: <String>{'startsAt'},
          nameManager: nameManager,
          package: package,
          isNullableOverride: true,
        );

        expect(result, isNotNull);
        expect(result!.type.symbol, 'DateTime');
        expect(result.type.isNullable, isTrue);
        expect(result.getter.lambda, isTrue);
        expect(
          collapseWhitespace(renderGetter(result.getter)),
          collapseWhitespace(
            formatBody(
              '''
static DateTime? get startsAtDefault => r'2024-01-01T00:00:00Z'
    .decodeJsonDateTime(context: r'Holder.startsAt');
''',
            ),
          ),
        );
      },
    );

    test(
      'nullable ClassModel decodes via fromJson without a dead null-check; '
      'the return type carries the nullable suffix but the const literal is '
      'statically non-null so the receiver-null guard is omitted',
      () {
        final pricing = ClassModel(
          isDeprecated: false,
          name: 'Pricing',
          properties: const [],
          context: context,
          examples: const [],
        );

        final result = resolveRuntimeDefault(
          normalizedName: 'pricing',
          specName: 'pricing',
          model: pricing,
          rawDefault: const <String, Object?>{},
          containerName: 'Holder',
          location: 'property',
          reservedNames: <String>{'pricing'},
          nameManager: nameManager,
          package: package,
          isNullableOverride: true,
        );

        expect(result, isNotNull);
        expect(result!.type.symbol, 'Pricing');
        expect(result.type.isNullable, isTrue);
        expect(result.getter.lambda, isTrue);
        expect(
          collapseWhitespace(renderGetter(result.getter)),
          collapseWhitespace(
            formatBody(
              '''
static Pricing? get pricingDefault =>
    Pricing.fromJson(const <String, Object?>{});
''',
            ),
          ),
        );
      },
    );

  });

  group('resolveRuntimeDefault — EnumModel', () {
    test(
      'nullable EnumModel default with valid value uses fromJson on the const '
      'literal and the return type carries the nullable suffix',
      () {
        final status = EnumModel<String>(
          isDeprecated: false,
          isNullable: true,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          context: context,
          examples: const [],
        );

        final result = resolveRuntimeDefault(
          normalizedName: 'status',
          specName: 'status',
          model: status,
          rawDefault: 'active',
          containerName: 'Holder',
          location: 'property',
          reservedNames: <String>{'status'},
          nameManager: nameManager,
          package: package,
          isNullableOverride: true,
        );

        expect(result, isNotNull);
        expect(result!.type.symbol, 'Status');
        expect(result.type.isNullable, isTrue);
        expect(result.getter.lambda, isTrue);
        expect(
          collapseWhitespace(renderGetter(result.getter)),
          collapseWhitespace(
            formatBody(
              '''
static Status? get statusDefault => Status.fromJson(r'active');
''',
            ),
          ),
        );
      },
    );
  });

  group('resolveRuntimeDefault — semantics', () {
    test('null raw default short-circuits to null without consuming a '
        'name', () {
      final reserved = <String>{'startsAt'};
      final result = resolveRuntimeDefault(
        normalizedName: 'startsAt',
        specName: 'startsAt',
        model: DateTimeModel(context: context),
        rawDefault: null,
        containerName: 'Holder',
        location: 'property',
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
        specName: 'startsAt',
        model: DateTimeModel(context: context),
        rawDefault: '2024-01-01T00:00:00Z',
        containerName: 'Holder',
        location: 'property',
        reservedNames: reserved,
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(result!.memberName, 'startsAtDefault2');
      expect(reserved.contains('startsAtDefault2'), isTrue);
    });

    test(
      'implausible default emits without warning — runtime DecodingException',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'DefaultResolution',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final result = resolveRuntimeDefault(
          normalizedName: 'startsAt',
          specName: 'startsAt',
          model: DateTimeModel(context: context),
          rawDefault: 42,
          containerName: 'Holder',
          location: 'property',
          reservedNames: <String>{'startsAt'},
          nameManager: nameManager,
          package: package,
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
        expect(
          logs.where((r) => r.level == Level.WARNING),
          isEmpty,
          reason:
              'the runtime decoder is the validator — no codegen-time '
              'warning fires for a plausibly-shaped but implausible default',
        );
      },
    );

    test(
      'non-JSON-encodable raw default (e.g. a YAML-parsed DateTime) returns '
      'null AND logs a warning identifying the property, location, expected '
      'type, rendered value, and rejected runtime type — so the silently '
      'dropped default is observable',
      () {
        final logs = <LogRecord>[];
        final sub = Logger(
          'DefaultResolution',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final yamlDateTime = DateTime.utc(2024, 6, 15);
        final result = resolveRuntimeDefault(
          normalizedName: 'startsAt',
          specName: 'startsAt',
          model: DateTimeModel(context: context),
          rawDefault: yamlDateTime,
          containerName: 'Holder',
          location: 'query',
          reservedNames: <String>{'startsAt'},
          nameManager: nameManager,
          package: package,
        );

        expect(result, isNull);
        final warnings = logs.where((r) => r.level == Level.WARNING).toList();
        expect(warnings, hasLength(1));
        final message = warnings.single.message;
        expect(message, contains('Holder.startsAt'));
        expect(message, contains('(query, expected DateTimeModel'));
        expect(message, contains('value: $yamlDateTime'));
        expect(
          message,
          contains('value of type DateTime is not JSON-encodable'),
        );
      },
    );
  });
}
