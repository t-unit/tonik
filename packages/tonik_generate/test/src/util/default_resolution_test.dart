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
          location: 'query',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: (_) {},
        );
        expect(result, isNull);
        expect(reserved, {'region'});
      },
    );

    test(
      'primitive type mismatch returns null and emits a unified warning '
      'with container, spec name, location, expected type, value, and reason',
      () {
        final messages = <String>[];
        final reserved = <String>{'name'};
        final result = resolveSingleDefault(
          normalizedName: 'name',
          specName: 'name',
          model: IntegerModel(context: context),
          rawDefault: 'not-a-number',
          containerName: 'BadOp',
          location: 'query',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );

        expect(result, isNull);
        expect(reserved, {'name'});
        expect(messages, hasLength(1));
        expect(
          messages.single,
          'Dropping default for BadOp.name (query, expected integer, '
          'value: "not-a-number"): '
          'value does not match the expected type.',
        );
      },
    );

    test(
      'non-const-materialisable primitive (DateTime) returns null and emits '
      'the const-expression reason',
      () {
        final messages = <String>[];
        final reserved = <String>{'since'};
        final result = resolveSingleDefault(
          normalizedName: 'since',
          specName: 'since',
          model: DateTimeModel(context: context),
          rawDefault: '2024-01-01T00:00:00Z',
          containerName: 'Op',
          location: 'query',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );

        expect(result, isNull);
        expect(messages, hasLength(1));
        expect(
          messages.single,
          'Dropping default for Op.since (query, expected string (date-time), '
          'value: "2024-01-01T00:00:00Z"): '
          'default value cannot be expressed as a const Dart expression '
          'for this type.',
        );
      },
    );

    test(
      'composite target (ClassModel) drops the default silently — no result, '
      'no warning, reserved names untouched',
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
          location: 'query',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );

        expect(result, isNull);
        expect(messages, isEmpty);
        expect(reserved, {'region'});
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
          location: 'query',
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

    test(
      'name collision against existing reserved name appends suffix',
      () {
        final reserved = <String>{'region', 'regionDefault'};
        final result = resolveSingleDefault(
          normalizedName: 'region',
          specName: 'region',
          model: StringModel(context: context),
          rawDefault: 'us',
          containerName: 'Op',
          location: 'query',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: (_) {},
        );

        expect(result, isNotNull);
        expect(result!.memberName, 'regionDefault2');
        expect(reserved.contains('regionDefault2'), isTrue);
      },
    );

    test(
      'null onDroppedDefault suppresses the warning while still returning null',
      () {
        final reserved = <String>{'page'};
        final result = resolveSingleDefault(
          normalizedName: 'page',
          specName: 'page',
          model: IntegerModel(context: context),
          rawDefault: 'not-a-number',
          containerName: 'BadOp',
          location: 'query',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: null,
        );
        expect(result, isNull);
        expect(reserved, {'page'});
      },
    );

    test(
      'isNullableOverride forces a nullable type reference on success',
      () {
        final reserved = <String>{'nickname'};
        final result = resolveSingleDefault(
          normalizedName: 'nickname',
          specName: 'nickname',
          model: StringModel(context: context),
          rawDefault: 'fallback',
          containerName: 'Holder',
          location: 'property',
          reservedNames: reserved,
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: (_) {},
          isNullableOverride: true,
        );

        expect(result, isNotNull);
        expect(result!.type.isNullable, isTrue);
        expect(result.type.accept(emitter).toString(), 'String?');
      },
    );

    test(
      'warning describes a non-JSON-encodable raw default via toString',
      () {
        final messages = <String>[];
        final yamlDateTime = DateTime.utc(2024, 6, 15);
        resolveSingleDefault(
          normalizedName: 'since',
          specName: 'since',
          model: DateTimeModel(context: context),
          rawDefault: yamlDateTime,
          containerName: 'Op',
          location: 'query',
          reservedNames: <String>{'since'},
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );
        expect(messages, hasLength(1));
        expect(messages.single, contains(yamlDateTime.toString()));
      },
    );

    test(
      'warning JSON-encodes a Map<String,Object?> raw default with valid keys',
      () {
        final messages = <String>[];
        resolveSingleDefault(
          normalizedName: 'value',
          specName: 'value',
          model: DateTimeModel(context: context),
          rawDefault: const <String, Object?>{'a': 1, 'b': null},
          containerName: 'Op',
          location: 'query',
          reservedNames: <String>{'value'},
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );
        expect(messages, hasLength(1));
        expect(messages.single, contains('{"a":1,"b":null}'));
      },
    );

    test(
      'property location label is preserved verbatim in the warning',
      () {
        final messages = <String>[];
        resolveSingleDefault(
          normalizedName: 'tier',
          specName: 'tier',
          model: IntegerModel(context: context),
          rawDefault: 'no',
          containerName: 'Mismatched',
          location: 'property',
          reservedNames: <String>{'tier'},
          nameManager: nameManager,
          package: 'api',
          onDroppedDefault: messages.add,
        );
        expect(messages, hasLength(1));
        expect(messages.single, contains('Mismatched.tier (property,'));
      },
    );
  });
}
