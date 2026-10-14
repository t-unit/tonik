import 'dart:convert';

import 'package:naming_api/naming_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('boolean field stays distinct from the encoding option', () {
    const disabled = BooleanEncodingOption(allowEmpty: false);
    const enabled = BooleanEncodingOption(allowEmpty: true);

    expect(disabled.allowEmpty, isFalse);
    expect(disabled.toJson(), {'allowEmpty': false});
    expect(
      (disabled.parameterProperties()['allowEmpty']! as ScalarPropertyValue)
          .value,
      'false',
    );
    expect(
      (enabled.parameterProperties(allowEmpty: false)['allowEmpty']!
              as ScalarPropertyValue)
          .value,
      'true',
    );
    expect(
      disabled.toSimple(explode: false, allowEmpty: true),
      'allowEmpty,false',
    );
    expect(
      disabled.toLabel(explode: true, allowEmpty: true),
      '.allowEmpty=false',
    );
    expect(
      disabled.toMatrix('filter', explode: true, allowEmpty: true),
      ';allowEmpty=false',
    );
    expect(disabled.toDeepObject('filter', explode: true, allowEmpty: true), [
      (name: 'filter[allowEmpty]', value: 'false'),
    ]);
  });

  test('optional field is omitted when absent and encoded when present', () {
    const absent = OptionalEncodingOption();
    const present = OptionalEncodingOption(allowEmpty: 'value');

    expect(absent.toJson(), <String, Object?>{});
    expect(absent.parameterProperties(), isEmpty);
    expect(
      present.toForm(
        'filter',
        explode: true,
        allowEmpty: false,
        textEncoding: utf8,
      ),
      [(name: 'allowEmpty', value: 'value')],
    );
  });

  test('list field keeps its values when the encoding option differs', () {
    const model = ListEncodingOption(allowEmpty: ['first', 'second']);

    expect(model.allowEmpty, ['first', 'second']);
    expect(
      (model.parameterProperties(allowEmpty: false)['allowEmpty']!
              as ArrayPropertyValue)
          .values,
      ['first', 'second'],
    );
    expect(
      model.toForm(
        'filter',
        explode: true,
        allowEmpty: false,
        textEncoding: utf8,
      ),
      [(name: 'allowEmpty', value: 'first,second')],
    );
  });

  test('mixed field reads its own scalar and omits null', () {
    const model = MixedEncodingOption(allowEmpty: false);
    const absent = MixedEncodingOption();

    expect(
      (model.parameterProperties()['allowEmpty']! as ScalarPropertyValue).value,
      'false',
    );
    expect(absent.parameterProperties(), isEmpty);
  });

  test('anyOf members remain distinct from encoder arguments', () {
    const explode = EncodingOptionAnyOf(explode: Explode.sample);
    const paramName = EncodingOptionAnyOf(paramName: ParamName.sample);
    const textEncoding = EncodingOptionAnyOf(textEncoding: TextEncoding.sample);
    const allowEmpty = EncodingOptionAnyOf(
      allowEmpty: AllowEmpty(enabled: false),
    );

    expect(explode.explode, Explode.sample);
    expect(explode.toSimple(explode: false, allowEmpty: false), 'sample');
    expect(explode.toLabel(explode: true, allowEmpty: false), '.sample');
    expect(
      paramName.toMatrix('filter', explode: false, allowEmpty: false),
      ';filter=sample',
    );
    expect(
      paramName.toForm(
        'filter',
        explode: true,
        allowEmpty: false,
        textEncoding: utf8,
      ),
      [(name: 'filter', value: 'sample')],
    );
    expect(
      textEncoding.uriEncode(allowEmpty: false, textEncoding: utf8),
      'sample',
    );
    expect(allowEmpty.currentEncodingShape, EncodingShape.complex);
    expect(allowEmpty.toJson(), {'enabled': false});
    expect(
      (allowEmpty.parameterProperties()['enabled']! as ScalarPropertyValue)
          .value,
      'false',
    );
  });

  test('allOf scalar members remain distinct from encoder arguments', () {
    const model = EncodingOptionAllOf(
      explode: Explode.sample,
      paramName: ParamName.sample,
      textEncoding: TextEncoding.sample,
    );

    expect(model.explode, Explode.sample);
    expect(model.toJson(), 'sample');
    expect(model.toSimple(explode: false, allowEmpty: false), 'sample');
    expect(model.toLabel(explode: true, allowEmpty: false), '.sample');
    expect(
      model.toMatrix('filter', explode: false, allowEmpty: false),
      ';filter=sample',
    );
    expect(
      model.toForm(
        'filter',
        explode: true,
        allowEmpty: false,
        textEncoding: utf8,
      ),
      [(name: 'filter', value: 'sample')],
    );
    expect(model.uriEncode(allowEmpty: false, textEncoding: utf8), 'sample');
  });

  test('allOf delegates object fields without shadowing allowEmpty', () {
    const model = EncodingObjectAllOf(
      allowEmpty: AllowEmpty(enabled: false),
      encodingLabel: EncodingLabel(label: 'label'),
    );

    expect(model.toJson(), {'enabled': false, 'label': 'label'});
    expect(
      (model.parameterProperties()['enabled']! as ScalarPropertyValue).value,
      'false',
    );
  });

  test('anyOf flat decoders keep explode separate from decoded members', () {
    final simple = EncodingOptionAnyOf.fromSimple('sample', explode: false);
    final form = EncodingOptionAnyOf.fromForm('sample', explode: true);

    expect(simple.explode, Explode.sample);
    expect(simple.paramName, ParamName.sample);
    expect(simple.textEncoding, TextEncoding.sample);
    expect(form.explode, Explode.sample);
    expect(form.paramName, ParamName.sample);
    expect(form.textEncoding, TextEncoding.sample);
  });

  test('anyOf JSON decoder keeps json separate from its decoded member', () {
    final model = JsonInputChoice.fromJson('sample');

    expect(model.json, Json.sample);
    expect(model.allowEmpty, isNull);
    expect(model.toJson(), 'sample');
  });
}
