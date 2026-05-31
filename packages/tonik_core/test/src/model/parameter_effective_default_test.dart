import 'package:test/test.dart';
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

  group('QueryParameterObject.effectiveDefaultValue', () {
    QueryParameterObject with$({
      required Object? defaultValue,
      required Model model,
    }) => QueryParameterObject(
      name: 'q',
      rawName: 'q',
      description: null,
      isRequired: false,
      isDeprecated: false,
      allowEmptyValue: false,
      allowReserved: false,
      explode: false,
      model: model,
      encoding: QueryParameterEncoding.form,
      context: context,
      examples: const [],
      defaultValue: defaultValue,
    );

    test('returns local default when set', () {
      final p = with$(
        defaultValue: 'local',
        model: StringModel(context: context),
      );
      expect(p.effectiveDefaultValue, 'local');
    });

    test('falls back to alias default when local is null', () {
      final p = with$(defaultValue: null, model: aliasWith('from-alias'));
      expect(p.effectiveDefaultValue, 'from-alias');
    });

    test('local default overrides alias default', () {
      final p = with$(defaultValue: 'local', model: aliasWith('from-alias'));
      expect(p.effectiveDefaultValue, 'local');
    });

    test('returns null when neither side carries a default', () {
      final p = with$(
        defaultValue: null,
        model: StringModel(context: context),
      );
      expect(p.effectiveDefaultValue, isNull);
    });
  });

  group('PathParameterObject.effectiveDefaultValue', () {
    PathParameterObject with$({
      required Object? defaultValue,
      required Model model,
    }) => PathParameterObject(
      name: 'p',
      rawName: 'p',
      description: null,
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: model,
      encoding: PathParameterEncoding.simple,
      context: context,
      examples: const [],
      defaultValue: defaultValue,
    );

    test('returns local default when set', () {
      final p = with$(
        defaultValue: 'x',
        model: StringModel(context: context),
      );
      expect(p.effectiveDefaultValue, 'x');
    });

    test('falls back to alias default when local is null', () {
      final p = with$(defaultValue: null, model: aliasWith('y'));
      expect(p.effectiveDefaultValue, 'y');
    });

    test('local default overrides alias default', () {
      final p = with$(defaultValue: 'z', model: aliasWith('y'));
      expect(p.effectiveDefaultValue, 'z');
    });
  });

  group('RequestHeaderObject.effectiveDefaultValue', () {
    RequestHeaderObject with$({
      required Object? defaultValue,
      required Model model,
    }) => RequestHeaderObject(
      name: 'h',
      rawName: 'h',
      description: null,
      isRequired: false,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: model,
      encoding: HeaderParameterEncoding.simple,
      context: context,
      examples: const [],
      defaultValue: defaultValue,
    );

    test('returns local default when set', () {
      final p = with$(
        defaultValue: 5,
        model: IntegerModel(context: context),
      );
      expect(p.effectiveDefaultValue, 5);
    });

    test('falls back to alias default when local is null', () {
      final p = with$(defaultValue: null, model: aliasWith('alias'));
      expect(p.effectiveDefaultValue, 'alias');
    });

    test('local default overrides alias default', () {
      final p = with$(defaultValue: 'local', model: aliasWith('alias'));
      expect(p.effectiveDefaultValue, 'local');
    });
  });

  group('CookieParameterObject.effectiveDefaultValue', () {
    CookieParameterObject with$({
      required Object? defaultValue,
      required Model model,
    }) => CookieParameterObject(
      name: 'c',
      rawName: 'c',
      description: null,
      isRequired: false,
      isDeprecated: false,
      explode: false,
      model: model,
      encoding: CookieParameterEncoding.form,
      context: context,
      examples: const [],
      defaultValue: defaultValue,
    );

    test('returns local default when set', () {
      final p = with$(
        defaultValue: true,
        model: BooleanModel(context: context),
      );
      expect(p.effectiveDefaultValue, isTrue);
    });

    test('falls back to alias default when local is null', () {
      final p = with$(defaultValue: null, model: aliasWith('a'));
      expect(p.effectiveDefaultValue, 'a');
    });

    test('local default overrides alias default', () {
      final p = with$(defaultValue: 'local', model: aliasWith('alias'));
      expect(p.effectiveDefaultValue, 'local');
    });
  });
}
