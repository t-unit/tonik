import 'dart:convert';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

class const _Object(final Map<String, PropertyValue> properties)
    extends ObjectParameterEncodable {
  @override
  Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) =>
      properties;

  @override
  Object? toJson() => const <String, Object?>{};
}

class const _HookObject(
  final Map<String, PropertyValue> Function({required bool allowEmpty})
  onProperties,
) extends ObjectParameterEncodable {
  @override
  Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) =>
      onProperties(allowEmpty: allowEmpty);

  @override
  Object? toJson() => null;
}

void main() {
  const object = _Object({
    'na me': PropertyValue.scalar('a/b,c'),
    'tags': PropertyValue.array(['x,y', 'z']),
  });
  final encoders =
      <String, Object Function(ParameterEncodable, {required bool allowEmpty})>{
        'simple': (value, {required bool allowEmpty}) =>
            value.toSimple(explode: true, allowEmpty: allowEmpty),
        'form': (value, {required bool allowEmpty}) => value.toForm(
          'filter',
          explode: true,
          allowEmpty: allowEmpty,
          textEncoding: utf8,
        ),
        'label': (value, {required bool allowEmpty}) =>
            value.toLabel(explode: true, allowEmpty: allowEmpty),
        'matrix': (value, {required bool allowEmpty}) =>
            value.toMatrix('filter', explode: true, allowEmpty: allowEmpty),
        'deepObject': (value, {required bool allowEmpty}) =>
            value.toDeepObject('filter', explode: true, allowEmpty: allowEmpty),
        'pipeDelimited': (value, {required bool allowEmpty}) =>
            value.toPipeDelimited('filter', allowEmpty: allowEmpty),
        'spaceDelimited': (value, {required bool allowEmpty}) =>
            value.toSpaceDelimited('filter', allowEmpty: allowEmpty),
      };

  test('const subclass is assignable to ParameterEncodable', () {
    const ParameterEncodable value = _Object({
      'name': PropertyValue.scalar('pet'),
    });
    expect(
      identical(value, const _Object({'name': PropertyValue.scalar('pet')})),
      isTrue,
    );
    expect(value.toSimple(explode: true, allowEmpty: false), 'name=pet');
    expect(value.toJson(), <String, Object?>{});
  });

  group('simple', () {
    test('escapes scalar commas but preserves array element boundaries', () {
      expect(
        object.toSimple(explode: true, allowEmpty: false),
        'na%20me=a%2Fb%2Cc,tags=x%2Cy,z',
      );
      expect(
        object.toSimple(explode: false, allowEmpty: false),
        'na%20me,a%2Fb%2Cc,tags,x%2Cy,z',
      );
    });

    test('literal bypasses escaping for keys, scalars, and array elements', () {
      expect(
        object.toSimple(explode: true, allowEmpty: false, literal: true),
        'na me=a/b,c,tags=x,y,z',
      );
      expect(
        object.toSimple(explode: false, allowEmpty: false, literal: true),
        'na me,a/b,c,tags,x,y,z',
      );
    });
  });

  group('form', () {
    test('defaults encode keys and comma-join array elements', () {
      expect(
        object.toForm(
          'filter',
          explode: true,
          allowEmpty: false,
          textEncoding: utf8,
        ),
        [
          (name: 'na%20me', value: 'a%2Fb%2Cc'),
          (name: 'tags', value: 'x%2Cy,z'),
        ],
      );
      expect(
        object.toForm(
          'filter',
          explode: false,
          allowEmpty: false,
          textEncoding: utf8,
        ),
        [(name: 'filter', value: 'na%20me,a%2Fb%2Cc,tags,x%2Cy,z')],
      );
    });

    const encoded = _Object({
      'a/b': PropertyValue.scalar('café /&=+'),
      'tags': PropertyValue.array(['a,b', 'c/d']),
      'plain': PropertyValue.scalar('/value'),
    });
    const fields = {
      'a/b': FormFieldEncoding(),
      'tags': FormFieldEncoding(explode: true, allowReserved: true),
    };

    test('forwards charset, query spaces, reserved and field overrides', () {
      expect(
        encoded.toForm(
          'filter',
          explode: true,
          allowEmpty: false,
          textEncoding: latin1,
          useQueryComponent: true,
          allowReserved: true,
          fieldEncodings: fields,
        ),
        [
          (name: 'a/b', value: 'caf%E9+%2F%26%3D%2B'),
          (name: 'tags', value: 'a,b'),
          (name: 'tags', value: 'c/d'),
          (name: 'plain', value: '/value'),
        ],
      );
    });

    test('collapsed objects ignore field overrides and join arrays', () {
      expect(
        encoded.toForm(
          'filter',
          explode: false,
          allowEmpty: false,
          textEncoding: latin1,
          useQueryComponent: true,
          allowReserved: true,
          fieldEncodings: fields,
        ),
        [
          (
            name: 'filter',
            value: 'a/b,caf%E9+/%26%3D%2B,tags,a,b,c/d,plain,/value',
          ),
        ],
      );
    });

    test('field explode distinguishes a scalar comma from array elements', () {
      const value = _Object({
        'scalar': PropertyValue.scalar('a,b'),
        'array': PropertyValue.array(['a', 'b']),
      });
      expect(
        value.toForm(
          'filter',
          explode: true,
          allowEmpty: false,
          textEncoding: utf8,
          fieldEncodings: const {
            'scalar': FormFieldEncoding(explode: true),
            'array': FormFieldEncoding(explode: true),
          },
        ),
        [
          (name: 'scalar', value: 'a%2Cb'),
          (name: 'array', value: 'a'),
          (name: 'array', value: 'b'),
        ],
      );
    });
  });

  test('label forwards explode and escapes typed property values', () {
    expect(
      object.toLabel(explode: true, allowEmpty: false),
      '.na%20me=a%2Fb%2Cc.tags=x%2Cy,z',
    );
    expect(
      object.toLabel(explode: false, allowEmpty: false),
      '.na%20me,a%2Fb%2Cc,tags,x%2Cy,z',
    );
  });

  test('matrix forwards parameter name and explode', () {
    expect(
      object.toMatrix('filter', explode: true, allowEmpty: false),
      ';na%20me=a%2Fb%2Cc;tags=x%2Cy,z',
    );
    expect(
      object.toMatrix('filter', explode: false, allowEmpty: false),
      ';filter=na%20me,a%2Fb%2Cc,tags,x%2Cy,z',
    );
  });

  group('deepObject', () {
    const value = _Object({'a/b': PropertyValue.scalar('/path?x=1&y=+')});

    test(
      'escapes keys even when reserved characters are allowed in values',
      () {
        expect(value.toDeepObject('filter', explode: true, allowEmpty: false), [
          (name: 'filter[a%2Fb]', value: '%2Fpath%3Fx%3D1%26y%3D%2B'),
        ]);
        expect(
          value.toDeepObject(
            'filter',
            explode: true,
            allowEmpty: false,
            allowReserved: true,
          ),
          [(name: 'filter[a%2Fb]', value: '/path?x%3D1%26y%3D%2B')],
        );
      },
    );

    test('rejects non-exploded objects with the existing exception', () {
      expect(
        () => value.toDeepObject('filter', explode: false, allowEmpty: true),
        throwsA(
          isA<EncodingException>().having(
            (error) => error.message,
            'message',
            'deepObject style requires explode=true',
          ),
        ),
      );
    });

    test('rejects array properties instead of treating them as scalars', () {
      expect(
        () => object.toDeepObject('filter', explode: true, allowEmpty: true),
        throwsA(
          isA<EncodingException>().having(
            (error) => error.message,
            'message',
            'Lists are not supported in this encoding style',
          ),
        ),
      );
    });
  });

  test('pipeDelimited preserves array tokens and forwards allowReserved', () {
    expect(object.toPipeDelimited('filter', allowEmpty: false), [
      (name: 'filter', value: 'na%20me|a%2Fb%2Cc|tags|x%2Cy|z'),
    ]);
    expect(
      object.toPipeDelimited('filter', allowEmpty: false, allowReserved: true),
      [(name: 'filter', value: 'na%20me|a/b,c|tags|x,y|z')],
    );
  });

  test('spaceDelimited preserves array tokens and forwards allowReserved', () {
    expect(object.toSpaceDelimited('filter', allowEmpty: false), [
      (name: 'filter', value: 'na%20me%20a%2Fb%2Cc%20tags%20x%2Cy%20z'),
    ]);
    expect(
      object.toSpaceDelimited('filter', allowEmpty: false, allowReserved: true),
      [(name: 'filter', value: 'na%20me%20a/b,c%20tags%20x,y%20z')],
    );
  });

  group('empty values', () {
    const empty = _Object({});
    const emptyValues = _Object({
      'scalar': PropertyValue.scalar(''),
      'array': PropertyValue.array([]),
    });

    test('empty objects preserve each style response when allowed', () {
      expect(empty.toSimple(explode: true, allowEmpty: true), '');
      expect(empty.toLabel(explode: true, allowEmpty: true), '.');
      expect(empty.toMatrix('filter', explode: false, allowEmpty: true), '');
      expect(
        empty.toForm(
          'filter',
          explode: true,
          allowEmpty: true,
          textEncoding: utf8,
        ),
        <ParameterEntry>[],
      );
      expect(
        empty.toDeepObject('filter', explode: true, allowEmpty: true),
        <ParameterEntry>[],
      );
      expect(
        empty.toPipeDelimited('filter', allowEmpty: true),
        <ParameterEntry>[],
      );
      expect(
        empty.toSpaceDelimited('filter', allowEmpty: true),
        <ParameterEntry>[],
      );
    });

    test('simple rejects empty objects when disallowed', () {
      expect(
        () => empty.toSimple(explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('form omits empty objects when allowEmpty=false', () {
      expect(
        empty.toForm(
          'filter',
          explode: true,
          allowEmpty: false,
          textEncoding: utf8,
        ),
        <ParameterEntry>[],
      );
    });

    test('label rejects empty objects when disallowed', () {
      expect(
        () => empty.toLabel(explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('matrix omits empty objects when allowEmpty=false', () {
      expect(empty.toMatrix('filter', explode: true, allowEmpty: false), '');
      expect(empty.toMatrix('filter', explode: false, allowEmpty: false), '');
    });

    test('deepObject rejects empty objects when disallowed', () {
      expect(
        () => empty.toDeepObject('filter', explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('pipeDelimited rejects empty objects when disallowed', () {
      expect(
        () => empty.toPipeDelimited('filter', allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('spaceDelimited rejects empty objects when disallowed', () {
      expect(
        () => empty.toSpaceDelimited('filter', allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test(
      'empty scalar and array properties remain valid for simple styles',
      () {
        expect(
          emptyValues.toSimple(explode: true, allowEmpty: false),
          'scalar,array',
        );
        expect(
          emptyValues.toSimple(explode: false, allowEmpty: false),
          'scalar,,array,',
        );
        expect(
          emptyValues.toLabel(explode: true, allowEmpty: false),
          '.scalar.array',
        );
        expect(
          emptyValues.toLabel(explode: false, allowEmpty: false),
          '.scalar,,array,',
        );
        expect(
          emptyValues.toMatrix('filter', explode: true, allowEmpty: false),
          ';scalar;array',
        );
        expect(
          emptyValues.toMatrix('filter', explode: false, allowEmpty: false),
          ';filter=scalar,,array,',
        );
        expect(emptyValues.toPipeDelimited('filter', allowEmpty: false), [
          (name: 'filter', value: 'scalar||array|'),
        ]);
        expect(emptyValues.toSpaceDelimited('filter', allowEmpty: false), [
          (name: 'filter', value: 'scalar%20%20array%20'),
        ]);
      },
    );

    test(
      'form omits empty arrays when exploded and preserves empty scalars',
      () {
        expect(
          emptyValues.toForm(
            'filter',
            explode: true,
            allowEmpty: true,
            textEncoding: utf8,
          ),
          [(name: 'scalar', value: '')],
        );
        expect(
          emptyValues.toForm(
            'filter',
            explode: false,
            allowEmpty: true,
            textEncoding: utf8,
          ),
          [(name: 'filter', value: 'scalar,,array,')],
        );
        expect(
          emptyValues.toForm(
            'filter',
            explode: true,
            allowEmpty: true,
            textEncoding: utf8,
            fieldEncodings: const {'scalar': FormFieldEncoding(explode: true)},
          ),
          <ParameterEntry>[],
        );
        for (final explode in [true, false]) {
          expect(
            () => emptyValues.toForm(
              'filter',
              explode: explode,
              allowEmpty: false,
              textEncoding: utf8,
            ),
            throwsA(isA<EmptyValueException>()),
          );
        }
      },
    );

    test(
      'deepObject accepts an empty scalar but rejects even an empty array',
      () {
        const scalar = _Object({'scalar': PropertyValue.scalar('')});
        expect(
          scalar.toDeepObject('filter', explode: true, allowEmpty: false),
          [(name: 'filter[scalar]', value: '')],
        );
        expect(
          () => emptyValues.toDeepObject(
            'filter',
            explode: true,
            allowEmpty: true,
          ),
          throwsA(
            isA<EncodingException>().having(
              (error) => error.message,
              'message',
              'Lists are not supported in this encoding style',
            ),
          ),
        );
      },
    );
  });

  group('subclass dispatch', () {
    for (final entry in encoders.entries) {
      test('${entry.key} calls the hook once per call with allowEmpty', () {
        final calls = <bool>[];
        final value = _HookObject(({required allowEmpty}) {
          calls.add(allowEmpty);
          return const {'name': PropertyValue.scalar('pet')};
        });
        entry.value(value, allowEmpty: false);
        entry.value(value, allowEmpty: true);
        expect(calls, [false, true]);
      });

      test('${entry.key} propagates the original hook exception', () {
        const error = EncodingException('Model-specific hook failure');
        final value = _HookObject(({required allowEmpty}) => throw error);
        expect(
          () => entry.value(value, allowEmpty: false),
          throwsA(same(error)),
        );
      });
    }

    test('inherited calls observe each fresh hook result', () {
      var count = 0;
      final value = _HookObject(
        ({required allowEmpty}) => {
          'count': PropertyValue.scalar('${++count}'),
        },
      );
      expect(value.toSimple(explode: true, allowEmpty: false), 'count=1');
      expect(value.toSimple(explode: true, allowEmpty: false), 'count=2');
    });

    test('hook runs before deepObject validates explode', () {
      const error = EncodingException('Read-only model');
      final value = _HookObject(({required allowEmpty}) => throw error);
      expect(
        () => value.toDeepObject('filter', explode: false, allowEmpty: false),
        throwsA(same(error)),
      );
    });
  });
}
