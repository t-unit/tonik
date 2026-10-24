import 'dart:convert';

import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('immutable list aliases retain JSON and value equality', () {
    final value = AnyOfListAlias.fromJson(const ['first', 'second']);
    final equalValue = AnyOfListAlias.fromJson(const ['first', 'second']);

    expect(value.toJson(), ['first', 'second']);
    expect(value, equalValue);
    expect(value.hashCode, equalValue.hashCode);
    expect(value.toSimple(explode: false, allowEmpty: true), 'first,second');
    expect(
      value
          .toForm('p', explode: false, allowEmpty: true, textEncoding: utf8)
          .single
          .value,
      'first,second',
    );
    expect(value.toLabel(explode: false, allowEmpty: true), '.first,second');
    expect(
      value.toMatrix('p', explode: false, allowEmpty: true),
      ';p=first,second',
    );
    expect(AnyOfListAlias.fromSimple('first,second', explode: false), value);
    expect(AnyOfListAlias.fromForm('first,second', explode: false), value);
  });

  test('immutable map aliases retain JSON and value equality', () {
    final value = AnyOfMapAlias.fromJson(const {'key': 'value'});
    final equalValue = AnyOfMapAlias.fromJson(const {'key': 'value'});

    expect(value.toJson(), {'key': 'value'});
    expect(value, equalValue);
    expect(value.hashCode, equalValue.hashCode);
  });

  test('immutable unsupported-only aliases fail parameter decoding', () {
    expect(
      () => AnyOfUnsupportedAliases.fromSimple('key,value', explode: false),
      throwsA(isA<SimpleDecodingException>()),
    );
    expect(
      () => AnyOfUnsupportedAliases.fromForm('key=value', explode: true),
      throwsA(isA<FormDecodingException>()),
    );
    expect(AnyOfUnsupportedAliases.fromJson(const {'key': 'value'}).toJson(), {
      'key': 'value',
    });
  });
}
