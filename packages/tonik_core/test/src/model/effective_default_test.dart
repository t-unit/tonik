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
  );

  group('effectiveDefault', () {
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
      );
      final inner = AliasModel(
        model: compound,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      final outer = AliasModel(
        model: inner,
        context: context,
        examples: const [],
        defaultValue: null,
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
        );
        final alias = AliasModel(
          model: compound,
          context: context,
          examples: const [],
          defaultValue: 2,
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
      );
      final allOf = AllOfModel(
        models: [member],
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      final oneOf = OneOfModel(
        models: [(discriminatorValue: null, model: member)],
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      final anyOf = AnyOfModel(
        models: [(discriminatorValue: null, model: member)],
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      final alias = AliasModel(
        model: allOf,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      expect(effectiveDefault(null, allOf), isNull);
      expect(effectiveDefault(null, oneOf), isNull);
      expect(effectiveDefault(null, anyOf), isNull);
      expect(alias.defaultValue, isNull);
    });
  });
}
