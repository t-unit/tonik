import 'dart:convert';

import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'form_value_helper.dart';

void main() {
  test('list aliases retain JSON values and deep equality', () {
    final value = AnyOfListAlias.fromJson(const ['first', 'second']);
    final equalValue = AnyOfListAlias.fromJson(const ['first', 'second']);

    expect(value.toJson(), ['first', 'second']);
    expect(value, equalValue);
    expect(value.hashCode, equalValue.hashCode);
    expect(value.currentEncodingShape, EncodingShape.complex);
    expect(value.parameterProperties, throwsA(isA<EncodingException>()));
  });

  test('list aliases support simple and form decoding', () {
    expect(AnyOfListAlias.fromSimple('first,second', explode: false).toJson(), [
      'first',
      'second',
    ]);
    expect(AnyOfListAlias.fromForm('first,second', explode: false).toJson(), [
      'first',
      'second',
    ]);
  });

  test('list aliases support simple, form, label and matrix encoding', () {
    final value = AnyOfListAlias.fromJson(const ['first', 'second']);

    expect(value.toSimple(explode: false, allowEmpty: true), 'first,second');
    expect(
      formValue(
        value.toForm('p', explode: false, allowEmpty: true, textEncoding: utf8),
        'p',
      ),
      'first,second',
    );
    expect(value.toLabel(explode: false, allowEmpty: true), '.first,second');
    expect(
      value.toMatrix('p', explode: false, allowEmpty: true),
      ';p=first,second',
    );
  });

  test('reference siblings preserve list behavior', () {
    final value = AnyOfListSibling.fromJson(const ['first', 'second']);
    final equalValue = AnyOfListSibling.fromJson(const ['first', 'second']);

    expect(value.toJson(), ['first', 'second']);
    expect(value, equalValue);
    expect(value.hashCode, equalValue.hashCode);
    expect(value.currentEncodingShape, EncodingShape.complex);
    expect(value.toSimple(explode: false, allowEmpty: true), 'first,second');
    expect(
      AnyOfListSibling.fromSimple('first,second', explode: false).toJson(),
      ['first', 'second'],
    );
  });

  test('map aliases retain JSON values and deep equality', () {
    final value = AnyOfMapAlias.fromJson(const {'key': 'value'});
    final equalValue = AnyOfMapAlias.fromJson(const {'key': 'value'});

    expect(value.toJson(), {'key': 'value'});
    expect(value, equalValue);
    expect(value.hashCode, equalValue.hashCode);
    expect(value.currentEncodingShape, EncodingShape.complex);
  });

  test('map aliases reject unsupported parameter styles', () {
    final value = AnyOfMapAlias.fromJson(const {'key': 'value'});

    expect(
      () => value.toSimple(explode: false, allowEmpty: true),
      throwsA(isA<EncodingException>()),
    );
    expect(
      () => value.toForm(
        'p',
        explode: false,
        allowEmpty: true,
        textEncoding: utf8,
      ),
      throwsA(isA<EncodingException>()),
    );
    expect(
      () => value.toLabel(explode: false, allowEmpty: true),
      throwsA(isA<EncodingException>()),
    );
    expect(
      () => value.toMatrix('p', explode: false, allowEmpty: true),
      throwsA(isA<EncodingException>()),
    );
    expect(value.parameterProperties, throwsA(isA<EncodingException>()));
    expect(
      () => AnyOfMapAlias.fromSimple('key,value', explode: false),
      throwsA(isA<SimpleDecodingException>()),
    );
    expect(
      () => AnyOfMapAlias.fromForm('key,value', explode: false),
      throwsA(isA<FormDecodingException>()),
    );
  });

  test('nested list aliases retain JSON but reject parameter encoding', () {
    final value = AnyOfNestedListAlias.fromJson(const [
      ['first', 'second'],
    ]);

    expect(value.toJson(), [
      ['first', 'second'],
    ]);
    expect(value.currentEncodingShape, EncodingShape.complex);
    expect(
      () => value.toSimple(explode: false, allowEmpty: true),
      throwsA(isA<EncodingException>()),
    );
    expect(
      () => AnyOfNestedListAlias.fromSimple('first,second', explode: false),
      throwsA(isA<SimpleDecodingException>()),
    );
    expect(
      () => AnyOfNestedListAlias.fromForm('first,second', explode: false),
      throwsA(isA<FormDecodingException>()),
    );
  });
}
