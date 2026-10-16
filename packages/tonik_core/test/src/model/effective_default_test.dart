import 'package:test/test.dart';
import 'package:tonik_core/src/model/effective_default.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  AliasModel aliasWith(Object? defaultValue) => AliasModel(
    name: 'A',
    model: StringModel(context: context),
    context: context,
    examples: const [],
    defaultValue: defaultValue,
    nameOverride: null,
    description: null,
    isDeprecated: false,
    isNullable: false,
    isReadOnly: false,
    isWriteOnly: false,
  );

  group('effectiveDefault', () {
    test('inherits a date-time enum default through an alias chain', () {
      final model = DateTimeEnumModel(
        values: {
          const EnumEntry(
            value: '2026-09-06T12:00:00.1000+02:00',
            nameOverride: null,
          ),
        },
        defaultValue: '2026-09-06T12:00:00.1000+02:00',
        isNullable: false,
        isDeprecated: false,
        context: context,
        examples: const [],
        name: null,
        nameOverride: null,
        description: null,
        fallbackValue: null,
        isReadOnly: false,
        isWriteOnly: false,
      );
      final inner = AliasModel(
        model: model,
        context: context,
        examples: const [],
        defaultValue: null,
        name: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );
      final outer = AliasModel(
        model: inner,
        context: context,
        examples: const [],
        defaultValue: null,
        name: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      expect(effectiveDefault(null, model), '2026-09-06T12:00:00.1000+02:00');
      expect(effectiveDefault(null, outer), '2026-09-06T12:00:00.1000+02:00');
      expect(outer.defaultValue, '2026-09-06T12:00:00.1000+02:00');
      expect(
        effectiveDefault('2026-09-06T12:00:00.100+02:00', outer),
        '2026-09-06T12:00:00.100+02:00',
      );
    });

    test('returns the local default when set, regardless of model type', () {
      expect(effectiveDefault('local', StringModel(context: context)), 'local');
    });

    test('returns the alias-carried default when local is null', () {
      expect(effectiveDefault(null, aliasWith('from-alias')), 'from-alias');
    });

    test('local default takes precedence over alias-carried default', () {
      expect(effectiveDefault('local', aliasWith('from-alias')), 'local');
    });

    test('returns null when neither local nor alias carry a default', () {
      expect(effectiveDefault(null, aliasWith(null)), isNull);
    });

    test('non-alias model with null local default returns null', () {
      expect(effectiveDefault(null, StringModel(context: context)), isNull);
    });

    test('local default is preserved verbatim — booleans, numbers, maps', () {
      expect(effectiveDefault(false, BooleanModel(context: context)), isFalse);
      expect(effectiveDefault(0, IntegerModel(context: context)), 0);
      expect(effectiveDefault(<String, Object?>{'k': 'v'}, aliasWith(null)), {
        'k': 'v',
      });
    });

    test('returns the enclosing allOf default, including zero', () {
      final model = AllOfModel(
        models: [IntegerModel(context: context)],
        context: context,
        isDeprecated: false,
        examples: const [],
        defaultValue: 0,
        name: null,
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      expect(effectiveDefault(null, model), 0);
    });

    test('returns the enclosing oneOf default, including false', () {
      final model = OneOfModel(
        models: [
          (discriminatorValue: null, model: BooleanModel(context: context)),
        ],
        context: context,
        isDeprecated: false,
        examples: const [],
        defaultValue: false,
        name: null,
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      expect(effectiveDefault(null, model), isFalse);
    });

    test('returns the enclosing anyOf object default unchanged', () {
      final model = AnyOfModel(
        models: [(discriminatorValue: null, model: AnyModel(context: context))],
        context: context,
        isDeprecated: false,
        examples: const [],
        defaultValue: const {'key': 'value'},
        name: null,
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      expect(effectiveDefault(null, model), {'key': 'value'});
    });

    test('follows aliases to the enclosing compound default', () {
      final compound = AllOfModel(
        models: [IntegerModel(context: context)],
        context: context,
        isDeprecated: false,
        examples: const [],
        defaultValue: 3,
        name: null,
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );
      final inner = AliasModel(
        model: compound,
        context: context,
        examples: const [],
        defaultValue: null,
        name: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );
      final outer = AliasModel(
        model: inner,
        context: context,
        examples: const [],
        defaultValue: null,
        name: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      expect(effectiveDefault(null, outer), 3);
      expect(outer.defaultValue, 3);
    });

    test(
      'local and alias defaults override the enclosing compound default',
      () {
        final compound = AllOfModel(
          models: [IntegerModel(context: context)],
          context: context,
          isDeprecated: false,
          examples: const [],
          defaultValue: 3,
          name: null,
          nameOverride: null,
          description: null,
          additionalPropertiesPolicy: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );
        final alias = AliasModel(
          model: compound,
          context: context,
          examples: const [],
          defaultValue: 2,
          name: null,
          nameOverride: null,
          description: null,
          isDeprecated: false,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );

        expect(effectiveDefault(0, compound), 0);
        expect(effectiveDefault(null, alias), 2);
        expect(effectiveDefault(0, alias), 0);
      },
    );

    test('compounds do not inherit defaults from their members', () {
      final member = AliasModel(
        model: IntegerModel(context: context),
        context: context,
        examples: const [],
        defaultValue: 7,
        name: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );
      final allOf = AllOfModel(
        models: [member],
        context: context,
        isDeprecated: false,
        examples: const [],
        name: null,
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );
      final oneOf = OneOfModel(
        models: [(discriminatorValue: null, model: member)],
        context: context,
        isDeprecated: false,
        examples: const [],
        name: null,
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );
      final anyOf = AnyOfModel(
        models: [(discriminatorValue: null, model: member)],
        context: context,
        isDeprecated: false,
        examples: const [],
        name: null,
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );
      final alias = AliasModel(
        model: allOf,
        context: context,
        examples: const [],
        defaultValue: null,
        name: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      expect(effectiveDefault(null, allOf), isNull);
      expect(effectiveDefault(null, oneOf), isNull);
      expect(effectiveDefault(null, anyOf), isNull);
      expect(alias.defaultValue, isNull);
    });
  });
}
