import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('immutable alias list properties decode through simple and form', () {
    final simple = AliasListParameters.fromSimple(
      'name,Bob,tags,first,second',
      explode: false,
    );
    final form = AliasListParameters.fromForm(
      'name=Bob&tags=first&tags=second',
      explode: true,
    );

    expect(simple.tags, isA<IList<String>>());
    expect(simple.tags?.unlock, ['first', 'second']);
    expect(form.tags, isA<IList<String>>());
    expect(form.tags?.unlock, ['first', 'second']);
    expect(simple, form);
  });

  test('immutable alias lists encode through parameter properties', () {
    final value = AliasListParameters(
      name: 'Bob',
      tags: (const ['first', 'second']).lock,
    );

    expect(
      (value.parameterProperties()['tags']! as ArrayPropertyValue).values,
      ['first', 'second'],
    );
    expect(
      value.toSimple(explode: false, allowEmpty: true),
      'name,Bob,tags,first,second',
    );
  });
}
