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

    test(
      'local default is preserved verbatim — booleans, numbers, maps',
      () {
        expect(
          effectiveDefault(false, BooleanModel(context: context)),
          isFalse,
        );
        expect(effectiveDefault(0, IntegerModel(context: context)), 0);
        expect(
          effectiveDefault(<String, Object?>{'k': 'v'}, aliasWith(null)),
          {'k': 'v'},
        );
      },
    );
  });
}
