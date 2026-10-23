// Allocate equal bodies separately to detect identity equality.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:additional_properties_api/additional_properties_api.dart';
import 'package:test/test.dart';

void main() {
  test('list response wrappers compare and hash by contents', () {
    final first = GetCollectionBodiesResponse200(body: ['a']);
    final second = GetCollectionBodiesResponse200(body: ['a']);
    final different = GetCollectionBodiesResponse200(body: ['b']);

    expect(first == second, isTrue);
    expect(first.hashCode, second.hashCode);
    expect(first == different, isFalse);
    expect({first, second, different}.length, 2);
  });

  test('aliased map response wrappers compare nested lists deeply', () {
    final first = GetCollectionBodiesResponse201(
      body: {
        'letters': ['a', 'b'],
        'empty': <String>[],
      },
    );
    final second = GetCollectionBodiesResponse201(
      body: {
        'empty': <String>[],
        'letters': ['a', 'b'],
      },
    );
    final different = GetCollectionBodiesResponse201(
      body: {
        'letters': ['b', 'a'],
        'empty': <String>[],
      },
    );

    expect(first == second, isTrue);
    expect(first.hashCode, second.hashCode);
    expect(first == different, isFalse);
    expect({first, second, different}.length, 2);
  });

  test('aliased nullable lists preserve collection and null equality', () {
    final first = GetCollectionBodiesResponse202(body: ['a']);
    final second = GetCollectionBodiesResponse202(body: ['a']);
    const absent = GetCollectionBodiesResponse202(body: null);
    const alsoAbsent = GetCollectionBodiesResponse202(body: null);
    final empty = GetCollectionBodiesResponse202(body: []);
    final alsoEmpty = GetCollectionBodiesResponse202(body: []);

    expect(first == second, isTrue);
    expect(first.hashCode, second.hashCode);
    expect(first == absent, isFalse);
    expect(absent == alsoAbsent, isTrue);
    expect(absent.hashCode, alsoAbsent.hashCode);
    expect(empty == alsoEmpty, isTrue);
    expect(empty.hashCode, alsoEmpty.hashCode);
    expect(empty == absent, isFalse);
  });
}
