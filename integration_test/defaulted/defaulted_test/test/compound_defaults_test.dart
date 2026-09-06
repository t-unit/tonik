import 'package:defaulted_api/defaulted_api.dart';
import 'package:defaulted_api/src/operation/get_compound_defaults.dart';
import 'package:test/test.dart';

void main() {
  final decoders = <String, Object? Function(Map<String, Object?>)>{
    'allOf': (json) => AllOfDefaults.fromJson(json).toJson(),
    'oneOf': (json) => OneOfDefaults.fromJson(json).toJson(),
    'anyOf': (json) => AnyOfDefaults.fromJson(json).toJson(),
  };
  const defaults = {
    'single': 3,
    'multiple': 3,
    'aliased': 3,
    'aliasOverride': 2,
    'overridden': 0,
    'inline': 3,
    'nullable': 3,
    'zero': 0,
    'disabled': false,
  };

  for (final MapEntry(key: kind, value: decode) in decoders.entries) {
    group('$kind enclosing defaults', () {
      test(
        'missing keys use defaults for single, multiple, and alias schemas',
        () {
          expect(decode({}), defaults);
        },
      );

      test('supplied values override defaults', () {
        final supplied = {
          for (final key in defaults.keys) key: key == 'disabled' ? true : 9,
        };
        expect(decode(supplied), supplied);
      });

      test('nullable explicit null wins over the non-null default', () {
        expect(decode({'nullable': null}), {
          for (final entry in defaults.entries)
            if (entry.key != 'nullable') entry.key: entry.value,
        });
      });

      test('null defaults and absent defaults retain no-default behavior', () {
        expect(decode({'nullDefault': null}), defaults);
        expect(decode({'nullDefault': 4, 'noDefault': 5}), {
          ...defaults,
          'nullDefault': 4,
          'noDefault': 5,
        });
      });

      test('defaults survive a JSON round-trip', () {
        final encoded = decode({})! as Map<String, Object?>;
        expect(decode(encoded), encoded);
      });
    });
  }

  test('compound defaults are public computed getters', () {
    expect(AllOfDefaults.singleDefault.toJson(), 3);
    expect(OneOfDefaults.multipleDefault.toJson(), 3);
    expect(AnyOfDefaults.aliasedDefault.toJson(), 3);
    expect(
      identical(AllOfDefaults.singleDefault, AllOfDefaults.singleDefault),
      isFalse,
    );
  });

  test('operation parameters expose referenced compound defaults', () {
    expect(GetCompoundDefaults.retriesDefault.toJson(), 3);
    expect(GetCompoundDefaults.choiceDefault.toJson(), 3);
    expect(GetCompoundDefaults.combinationDefault.toJson(), 3);
    expect(GetCompoundDefaults.enabledDefault.toJson(), isFalse);
  });
}
