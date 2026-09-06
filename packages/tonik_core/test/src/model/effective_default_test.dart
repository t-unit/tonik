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

    final factories = <String, CompositeModel Function(Object?, Model)>{
      'allOf': (value, member) => AllOfModel(
        models: [member],
        context: context,
        isDeprecated: false,
        examples: const [],
        defaultValue: value,
      ),
      'oneOf': (value, member) => OneOfModel(
        models: [(discriminatorValue: null, model: member)],
        context: context,
        isDeprecated: false,
        examples: const [],
        defaultValue: value,
      ),
      'anyOf': (value, member) => AnyOfModel(
        models: [(discriminatorValue: null, model: member)],
        context: context,
        isDeprecated: false,
        examples: const [],
        defaultValue: value,
      ),
    };

    for (final MapEntry(key: kind, value: create) in factories.entries) {
      group(kind, () {
        test(
          'preserves enclosing defaults directly and through alias chains',
          () {
            for (final value in <Object>[
              3,
              0,
              false,
              {'key': 'value'},
              <int>[],
            ]) {
              final compound = create(value, aliasWith('member-default'));
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

              expect(effectiveDefault(null, compound), value);
              expect(effectiveDefault(null, outer), value);
              expect(outer.defaultValue, value);
            }
          },
        );

        test('local and nearest alias defaults take precedence', () {
          final compound = create(3, aliasWith(1));
          final alias = AliasModel(
            model: compound,
            context: context,
            examples: const [],
            defaultValue: 2,
          );
          expect(effectiveDefault(0, compound), 0);
          expect(effectiveDefault(null, alias), 2);
          expect(effectiveDefault(false, alias), isFalse);
        });

        test('a null enclosing default does not inherit member defaults', () {
          final compound = create(null, aliasWith('member-default'));
          final alias = AliasModel(
            model: compound,
            context: context,
            examples: const [],
            defaultValue: null,
          );
          expect(effectiveDefault(null, compound), isNull);
          expect(alias.defaultValue, isNull);
        });
      });
    }
  });
}
