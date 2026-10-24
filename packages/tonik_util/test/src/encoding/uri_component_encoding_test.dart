import 'dart:convert';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('keeps only unreserved punctuation literal', () {
    expect(
      "AZaz09-._~ !'()*+%é".uriEncode(allowEmpty: true, textEncoding: utf8),
      'AZaz09-._~%20%21%27%28%29%2A%2B%25%C3%A9',
    );
  });

  test('preserves form-body spaces and the selected charset', () {
    expect(
      "é !'()*+".uriEncode(
        allowEmpty: true,
        useQueryComponent: true,
        textEncoding: latin1,
      ),
      '%E9+%21%27%28%29%2A%2B',
    );
    expect(
      "é !'()*+".uriEncode(allowEmpty: true, textEncoding: latin1),
      '%E9%20%21%27%28%29%2A%2B',
    );
  });

  test(
    'escapes simple map keys and values without altering literal headers',
    () {
      expect(
        {"!'": '()*'}.toSimple(explode: true, allowEmpty: true),
        '%21%27=%28%29%2A',
      );
      expect(
        {"!'": '()*'}.toSimple(explode: true, allowEmpty: true, literal: true),
        "!'=()*",
      );
      expect(
        {'!': '%2A'}
            .toSimple(explode: true, allowEmpty: true, alreadyEncoded: true),
        '%21=%2A',
      );
    },
  );

  test('escapes exploded label and matrix components', () {
    expect(
      {'!': '*()'}.toLabel(explode: true, allowEmpty: true),
      '.%21=%2A%28%29',
    );
    expect(
      {'!': '*()'}.toMatrix('p', explode: true, allowEmpty: true),
      ';%21=%2A%28%29',
    );
    expect(
      ["!'()*"].toMatrix('p', explode: true, allowEmpty: true),
      ';p=%21%27%28%29%2A',
    );
    expect(
      ['%2A']
          .toMatrix('p', explode: true, allowEmpty: true, alreadyEncoded: true),
      ';p=%2A',
    );
  });

  test('escapes binary values in path styles', () {
    expect(
      [33, 39, 40, 41, 42].toSimple(explode: false, allowEmpty: true),
      '%21%27%28%29%2A',
    );
    expect(
      [33, 39, 40, 41, 42].toLabel(explode: false, allowEmpty: true),
      '.%21%27%28%29%2A',
    );
    expect(
      [33, 39, 40, 41, 42].toMatrix('p', explode: false, allowEmpty: true),
      ';p=%21%27%28%29%2A',
    );
  });

  test('escapes deep-object names and keys even with reserved values', () {
    expect(
      {"!'": '()*'}.toDeepObject(
        'p!',
        explode: true,
        allowEmpty: true,
        allowReserved: true,
      ),
      [(name: 'p%21[%21%27]', value: '()*')],
    );
  });

  test('escapes delimited map components and dynamic list names', () {
    expect({'!': '*'}.toPipeDelimited('p!', allowEmpty: true), [
      (name: 'p%21', value: '%21|%2A'),
    ]);
    expect(encodeAnyToSpaceDelimited(["!'", '()*'], 'p!', allowEmpty: true), [
      (name: 'p%21', value: '%21%27%20%28%29%2A'),
    ]);
  });

  test('escapes generated model property keys and values', () {
    const properties = {'!': PropertyValue.scalar('*')};
    expect(properties.toSimple(explode: true, allowEmpty: true), '%21=%2A');
    expect(properties.toLabel(explode: true, allowEmpty: true), '.%21=%2A');
    expect(
      properties.toMatrix('p', explode: true, allowEmpty: true),
      ';%21=%2A',
    );
    expect(properties.toDeepObject('p!', explode: true, allowEmpty: true), [
      (name: 'p%21[%21]', value: '%2A'),
    ]);
  });
}
