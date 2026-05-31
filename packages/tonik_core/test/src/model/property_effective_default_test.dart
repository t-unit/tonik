import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  Property propertyWith({
    required Object? defaultValue,
    required Model model,
  }) => Property(
    name: 'p',
    model: model,
    isRequired: false,
    isNullable: false,
    isDeprecated: false,
    examples: const [],
    defaultValue: defaultValue,
  );

  group('Property.effectiveDefaultValue', () {
    test('returns the local default when set', () {
      final property = propertyWith(
        defaultValue: 'local',
        model: StringModel(context: context),
      );
      expect(property.effectiveDefaultValue, 'local');
    });

    test('falls back to alias-carried default when local is null', () {
      final alias = AliasModel(
        name: 'A',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: 'from-alias',
      );
      final property = propertyWith(defaultValue: null, model: alias);
      expect(property.effectiveDefaultValue, 'from-alias');
    });

    test('local default overrides alias-carried default', () {
      final alias = AliasModel(
        name: 'A',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: 'from-alias',
      );
      final property = propertyWith(defaultValue: 'local', model: alias);
      expect(property.effectiveDefaultValue, 'local');
    });

    test('returns null when neither side carries a default', () {
      final property = propertyWith(
        defaultValue: null,
        model: StringModel(context: context),
      );
      expect(property.effectiveDefaultValue, isNull);
    });
  });
}
