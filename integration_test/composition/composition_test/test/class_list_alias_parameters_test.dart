import 'dart:convert';

import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test(
    'simple decoding consumes the final aliased list like a direct list',
    () {
      final value = AliasListParameters.fromSimple(
        'name,Bob,tags,first,second',
        explode: false,
      );
      final direct = DirectListParameters.fromSimple(
        'name,Bob,tags,first,second',
        explode: false,
      );

      expect(value.name, 'Bob');
      expect(value.tags, ['first', 'second']);
      expect(value.toJson(), {
        'name': 'Bob',
        'tags': ['first', 'second'],
      });
      expect(direct.toJson(), {
        'name': 'Bob',
        'tags': ['first', 'second'],
      });
    },
  );

  test('aliased header lists preserve direct-list quote behavior', () {
    final value = AliasListParameters.fromSimple(
      'name=Bob,tags="first,part",second',
      explode: true,
      isHeader: true,
    );
    final direct = DirectListParameters.fromSimple(
      'name=Bob,tags="first,part",second',
      explode: true,
      isHeader: true,
    );

    expect(value.name, 'Bob');
    expect(direct.name, 'Bob');
    expect(value.tags, ['"first,part"', 'second']);
    expect(direct.tags, ['"first,part"', 'second']);
    expect(value.toJson(), {
      'name': 'Bob',
      'tags': ['"first,part"', 'second'],
    });
    expect(direct.toJson(), {
      'name': 'Bob',
      'tags': ['"first,part"', 'second'],
    });
  });

  test('form decoding joins repeated alias list keys', () {
    final value = AliasListParameters.fromForm(
      'name=Bob&tags=first&tags=second',
      explode: true,
    );

    expect(value.name, 'Bob');
    expect(value.tags, ['first', 'second']);
  });

  test('form decoding consumes the final alias list', () {
    final value = AliasListParameters.fromForm(
      'name,Bob,tags,first,second',
      explode: false,
    );

    expect(value.name, 'Bob');
    expect(value.tags, ['first', 'second']);
  });

  test('reference siblings retain list decoding and parameter properties', () {
    final value = SiblingListParameters.fromForm(
      'name=Bob&tags=first&tags=second',
      explode: true,
    );
    final simple = SiblingListParameters.fromSimple(
      'name,Bob,tags,first,second',
      explode: false,
    );
    final properties = value.parameterProperties();

    expect(value.tags, ['first', 'second']);
    expect(simple.tags, ['first', 'second']);
    expect((properties['tags']! as ArrayPropertyValue).values, [
      'first',
      'second',
    ]);
  });

  test('parameter properties retain scalar and array boundaries', () {
    const value = AliasListParameters(name: 'Bob', tags: ['first', 'second']);
    final properties = value.parameterProperties();

    expect((properties['name']! as ScalarPropertyValue).value, 'Bob');
    expect((properties['tags']! as ArrayPropertyValue).values, [
      'first',
      'second',
    ]);
    expect(
      value.toSimple(explode: false, allowEmpty: true),
      'name,Bob,tags,first,second',
    );
    expect(
      value.toForm('p', explode: true, allowEmpty: true, textEncoding: utf8),
      const [
        (name: 'name', value: 'Bob'),
        (name: 'tags', value: 'first,second'),
      ],
    );
    expect(
      value.toMatrix('p', explode: false, allowEmpty: true),
      ';p=name,Bob,tags,first,second',
    );
  });

  test('absent optional alias lists remain absent', () {
    final value = AliasListParameters.fromForm('name=Bob', explode: true);

    expect(value.tags, isNull);
    expect(value.parameterProperties().keys, ['name']);
    expect(value.toJson(), {'name': 'Bob'});
  });

  test('nullable alias lists retain nullability during parameter encoding', () {
    const absent = NullableAliasListParameters(tags: null);
    const present = NullableAliasListParameters(tags: ['first', 'second']);

    expect(absent.parameterProperties(), isEmpty);
    expect(
      (present.parameterProperties()['tags']! as ArrayPropertyValue).values,
      ['first', 'second'],
    );
  });

  test('nested alias lists still reject unsupported parameter encoding', () {
    const value = NestedListParameters(
      tags: [
        ['first'],
      ],
    );

    expect(value.parameterProperties, throwsA(isA<EncodingException>()));
    expect(
      () => NestedListParameters.fromSimple('tags,first', explode: false),
      throwsA(isA<SimpleDecodingException>()),
    );
    expect(
      () => NestedListParameters.fromForm('tags=first', explode: true),
      throwsA(isA<FormDecodingException>()),
    );
  });
}
