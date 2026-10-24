import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';

void main() {
  test(
    'retains an undeclared discriminator while decoding all valid members',
    () {
      const json = <String, Object?>{'kind': 'rect', 'width': 2};
      final value = AnyOfFigure.fromJson(json);

      expect(value.optionalOval, isNotNull);
      expect(value.optionalRect, isNotNull);
      expect(value.toJson(), {'kind': 'rect', 'width': 2});
      expect(json, {'kind': 'rect', 'width': 2});
    },
  );

  test('copyWith preserves the undeclared discriminator', () {
    final value = AnyOfFigure.fromJson(const {'kind': 'rect', 'width': 2});

    expect(value.copyWith().toJson(), {'kind': 'rect', 'width': 2});
    expect(
      value.copyWith(optionalRect: const OptionalRect(width: 3)).toJson(),
      {'kind': 'rect', 'width': 3},
    );
  });

  test('retains unknown discriminator values', () {
    final value = AnyOfFigure.fromJson(const {'kind': 'triangle', 'width': 2});

    expect(value.optionalOval, isNotNull);
    expect(value.optionalRect, isNotNull);
    expect(value.toJson(), {'kind': 'triangle', 'width': 2});
  });

  test('retains explicit null discriminator values', () {
    final value = AnyOfFigure.fromJson(const {'kind': null, 'width': 2});

    expect(value.toJson(), {'kind': null, 'width': 2});
    expect(value.copyWith().toJson(), {'kind': null, 'width': 2});
  });

  test('retains non-string discriminator values accepted by the members', () {
    final value = AnyOfFigure.fromJson(const {'kind': 7, 'width': 2});

    expect(value.toJson(), {'kind': 7, 'width': 2});
  });

  test('missing discriminators retain the existing mapping fallback', () {
    final value = AnyOfFigure.fromJson(const {'width': 2});

    expect(value.toJson(), {'kind': 'oval', 'width': 2});
    expect(value.copyWith().toJson(), {'kind': 'oval', 'width': 2});
  });

  test('manual construction retains the existing mapping fallback', () {
    const value = AnyOfFigure(optionalRect: OptionalRect(width: 2));

    expect(value.toJson(), {'kind': 'rect', 'width': 2});
    expect(value.copyWith().toJson(), {'kind': 'rect', 'width': 2});
  });

  test('declared discriminator members retain round trips and equality', () {
    final value = AnyOfDeclaredFigure.fromJson(const {
      'kind': 'rect',
      'width': 2,
    });
    const manual = AnyOfDeclaredFigure(
      declaredOval: DeclaredOval(kind: 'rect'),
      declaredRect: DeclaredRect(kind: 'rect', width: 2),
    );

    expect(value.declaredOval, isNotNull);
    expect(value.declaredRect, isNotNull);
    expect(value.toJson(), {'kind': 'rect', 'width': 2});
    expect(value, manual);
    expect(value.hashCode, manual.hashCode);
    expect(value.copyWith(), value);
  });

  test(
    'copyWith edits to declared discriminators override retained metadata',
    () {
      final value = AnyOfDeclaredFigure.fromJson(const {
        'kind': 'rect',
        'width': 2,
      });
      final updated = value.copyWith(
        declaredOval: const DeclaredOval(kind: 'oval'),
        declaredRect: const DeclaredRect(kind: 'oval', width: 3),
      );

      expect(updated.toJson(), {'kind': 'oval', 'width': 3});
    },
  );
}
