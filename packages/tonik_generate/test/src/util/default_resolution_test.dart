import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/default_resolution.dart';

void main() {
  late NameManager nameManager;
  late Context context;
  late DartEmitter emitter;

  setUp(() {
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  String renderAssignment(Code? assignment) =>
      assignment == null ? '' : assignment.accept(emitter).toString();

  group('resolveSingleDefault', () {
    test(
      'absent raw default returns null without touching reserved names',
      () {
        final reserved = <String>{'region'};
        final result = resolveSingleDefault(
          normalizedName: 'region',
          specName: 'region',
          model: StringModel(context: context),
          rawDefault: null,
          containerName: 'Op',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: (_) {},
        );
        expect(result, isNull);
        expect(reserved, {'region'});
      },
    );

    test('primitive type mismatch warns with container.specName only', () {
      final messages = <String>[];
      final reserved = <String>{'name'};
      final result = resolveSingleDefault(
        normalizedName: 'name',
        specName: 'name',
        model: IntegerModel(context: context),
        rawDefault: 'not-a-number',
        containerName: 'BadOp',
        reservedNames: reserved,
        nameManager: nameManager,
        package: 'api',
        onDroppedDefault: messages.add,
      );

      expect(result, isNull);
      expect(reserved, {'name'});
      expect(messages, ['Dropping default for BadOp.name.']);
    });

    test(
      'non-const-materialisable primitive (DateTime) returns null silently — '
      'the caller routes it to the runtime fallback',
      () {
        final messages = <String>[];
        final reserved = <String>{'since'};
        final result = resolveSingleDefault(
          normalizedName: 'since',
          specName: 'since',
          model: DateTimeModel(context: context),
          rawDefault: '2024-01-01T00:00:00Z',
          containerName: 'Op',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );

        expect(result, isNull);
        expect(messages, isEmpty);
      },
    );

    test(
      'ClassModel target returns null silently — the caller routes it to the '
      'runtime fallback',
      () {
        final messages = <String>[];
        final reserved = <String>{'region'};
        final result = resolveSingleDefault(
          normalizedName: 'region',
          specName: 'region',
          model: ClassModel(
            isDeprecated: false,
            name: 'Region',
            properties: const [],
            context: context,
            examples: const [],
          ),
          rawDefault: const <String, Object?>{},
          containerName: 'Op',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );

        expect(result, isNull);
        expect(reserved, {'region'});
        expect(messages, isEmpty);
      },
    );

    test(
      'success path returns memberName, materialised value, and type; '
      'mutates reserved names',
      () {
        final reserved = <String>{'region'};
        final result = resolveSingleDefault(
          normalizedName: 'region',
          specName: 'region',
          model: StringModel(context: context),
          rawDefault: 'us',
          containerName: 'Op',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: (_) {},
        );

        expect(result, isNotNull);
        expect(result!.memberName, 'regionDefault');
        expect(result.type.symbol, 'String');
        expect(reserved, {'region', 'regionDefault'});

        final field = defaultField(result);
        expect(field.static, isTrue);
        expect(field.modifier, FieldModifier.constant);
        expect(field.name, 'regionDefault');
        expect(field.type?.symbol, 'String');
        expect(renderAssignment(field.assignment), "r'us'");
      },
    );

    test('name collision against existing reserved name appends suffix', () {
      final reserved = <String>{'region', 'regionDefault'};
      final result = resolveSingleDefault(
        normalizedName: 'region',
        specName: 'region',
        model: StringModel(context: context),
        rawDefault: 'us',
        containerName: 'Op',
        reservedNames: reserved,
        nameManager: nameManager,
        package: 'api',
        onDroppedDefault: (_) {},
      );

      expect(result, isNotNull);
      expect(result!.memberName, 'regionDefault2');
      expect(reserved.contains('regionDefault2'), isTrue);
    });

    test('null onDroppedDefault stays silent on a drop', () {
      final reserved = <String>{'page'};
      final result = resolveSingleDefault(
        normalizedName: 'page',
        specName: 'page',
        model: IntegerModel(context: context),
        rawDefault: 'not-a-number',
        containerName: 'BadOp',
        reservedNames: reserved,
        nameManager: nameManager,
        package: 'api',
        onDroppedDefault: null,
      );
      expect(result, isNull);
      expect(reserved, {'page'});
    });

    test('isNullableOverride forces a nullable type reference on success', () {
      final reserved = <String>{'nickname'};
      final result = resolveSingleDefault(
        normalizedName: 'nickname',
        specName: 'nickname',
        model: StringModel(context: context),
        rawDefault: 'fallback',
        containerName: 'Holder',
        reservedNames: reserved,
        nameManager: nameManager,
        package: 'api',
        onDroppedDefault: (_) {},
        isNullableOverride: true,
      );

      expect(result, isNotNull);
      expect(result!.type.isNullable, isTrue);
      expect(result.type.accept(emitter).toString(), 'String?');
    });

    test(
      'nullable enum with a value present in the enum returns null silently — '
      'the caller routes it to the runtime fallback',
      () {
        final messages = <String>[];
        final reserved = <String>{'status'};
        final result = resolveSingleDefault(
          normalizedName: 'status',
          specName: 'status',
          model: EnumModel<String>(
            name: 'Status',
            values: {
              const EnumEntry<String>(value: 'active'),
              const EnumEntry<String>(value: 'inactive'),
            },
            isNullable: true,
            context: context,
            isDeprecated: false,
            examples: const [],
          ),
          rawDefault: 'active',
          containerName: 'Op',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );

        expect(result, isNull);
        expect(reserved, {'status'});
        expect(messages, isEmpty);
      },
    );

    test('enum default outside the enum values warns once', () {
      final messages = <String>[];
      resolveSingleDefault(
        normalizedName: 'status',
        specName: 'status',
        model: EnumModel<String>(
          name: 'Status',
          values: {
            const EnumEntry<String>(value: 'active'),
            const EnumEntry<String>(value: 'inactive'),
          },
          isNullable: true,
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
        rawDefault: 'archived',
        containerName: 'Op',
        reservedNames: <String>{'status'},
        nameManager: nameManager,
        package: 'api',
        onDroppedDefault: messages.add,
      );

      expect(messages, ['Dropping default for Op.status.']);
    });

    test('ListModel<StringModel> with non-List JSON warns once', () {
      final messages = <String>[];
      final reserved = <String>{'tags'};
      final result = resolveSingleDefault(
        normalizedName: 'tags',
        specName: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        rawDefault: 'not-a-list',
        containerName: 'Op',
        reservedNames: reserved,
        nameManager: nameManager,
        package: 'api',
        onDroppedDefault: messages.add,
      );

      expect(result, isNull);
      expect(reserved, {'tags'});
      expect(messages, ['Dropping default for Op.tags.']);
    });

    test(
      'ListModel<DateTimeModel> with valid-shape list returns null silently — '
      'the inner leaf bubbles up for runtime-fallback handling',
      () {
        final messages = <String>[];
        resolveSingleDefault(
          normalizedName: 'since',
          specName: 'since',
          model: ListModel(
            content: DateTimeModel(context: context),
            context: context,
            examples: const [],
          ),
          rawDefault: const <Object?>['2024-01-01'],
          containerName: 'Op',
          reservedNames: <String>{'since'},
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );

        expect(messages, isEmpty);
      },
    );

    test('MapModel<IntegerModel> with non-Map JSON warns once', () {
      final messages = <String>[];
      resolveSingleDefault(
        normalizedName: 'counts',
        specName: 'counts',
        model: MapModel(
          valueModel: IntegerModel(context: context),
          context: context,
          examples: const [],
        ),
        rawDefault: 'not-a-map',
        containerName: 'Op',
        reservedNames: <String>{'counts'},
        nameManager: nameManager,
        package: 'api',
        onDroppedDefault: messages.add,
      );

      expect(messages, ['Dropping default for Op.counts.']);
    });

    test(
      'MapModel<ClassModel> with valid-shape Map returns null silently — '
      'the inner leaf bubbles up for runtime-fallback handling',
      () {
        final messages = <String>[];
        resolveSingleDefault(
          normalizedName: 'index',
          specName: 'index',
          model: MapModel(
            valueModel: ClassModel(
              name: 'Address',
              isDeprecated: false,
              properties: const [],
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          ),
          rawDefault: const <String, Object?>{'a': <String, Object?>{}},
          containerName: 'Op',
          reservedNames: <String>{'index'},
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );

        expect(messages, isEmpty);
      },
    );

    test('AnyModel with non-JSON outer value (DateTime) warns once', () {
      final messages = <String>[];
      final yamlDateTime = DateTime.utc(2024, 6, 15);
      resolveSingleDefault(
        normalizedName: 'raw',
        specName: 'raw',
        model: AnyModel(context: context),
        rawDefault: yamlDateTime,
        containerName: 'Op',
        reservedNames: <String>{'raw'},
        nameManager: nameManager,
        package: 'api',
        onDroppedDefault: messages.add,
      );

      expect(messages, ['Dropping default for Op.raw.']);
    });

    test(
      'AnyModel with a Map carrying a non-String key returns null silently — '
      'non-String keys are classified as an inner-value failure that bubbles '
      'to the runtime fallback',
      () {
        final messages = <String>[];
        final nonStringKeyMap = <int, String>{1: 'one'};
        resolveSingleDefault(
          normalizedName: 'raw',
          specName: 'raw',
          model: AnyModel(context: context),
          rawDefault: nonStringKeyMap,
          containerName: 'Op',
          reservedNames: <String>{'raw'},
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );

        expect(messages, isEmpty);
      },
    );

    test(
      'ClassModel target with a non-empty default returns null silently — '
      'the caller routes it to the runtime fallback',
      () {
        final messages = <String>[];
        final reserved = <String>{'profile'};
        final result = resolveSingleDefault(
          normalizedName: 'profile',
          specName: 'profile',
          model: ClassModel(
            isDeprecated: false,
            name: 'Profile',
            properties: const [],
            context: context,
            examples: const [],
          ),
          rawDefault: const <String, Object?>{'field': 'value'},
          containerName: 'Op',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );

        expect(result, isNull);
        expect(reserved, {'profile'});
        expect(messages, isEmpty);
      },
    );

    test(
      'AllOf / OneOf / AnyOf composite targets drop silently — no warning, '
      'no result, reserved names untouched',
      () {
        for (final model in <Model>[
          AllOfModel(
            name: 'A',
            isDeprecated: false,
            models: const {},
            context: context,
            examples: const [],
          ),
          OneOfModel(
            name: 'O',
            isDeprecated: false,
            models: const {},
            context: context,
            examples: const [],
          ),
          AnyOfModel(
            name: 'N',
            isDeprecated: false,
            models: const {},
            context: context,
            examples: const [],
          ),
        ]) {
          final messages = <String>[];
          final reserved = <String>{'composite'};
          final result = resolveSingleDefault(
            normalizedName: 'composite',
            specName: 'composite',
            model: model,
            rawDefault: const <String, Object?>{'anything': 1},
            containerName: 'Op',
            reservedNames: reserved,
            nameManager: nameManager,
            package: 'api',
            onDroppedDefault: messages.add,
          );

          expect(result, isNull);
          expect(messages, isEmpty);
          expect(reserved, {'composite'});
        }
      },
    );
  });
}
