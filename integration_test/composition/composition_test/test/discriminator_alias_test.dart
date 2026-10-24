import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';

void main() {
  test('oneOf decodes the canonical mapping value', () {
    final shape = AliasedShape.fromJson(const {
      'shapeType': 'square',
      'side': 2,
    });

    expect(shape, isA<AliasedShapeAliasedSquare>());
    expect(shape.toJson(), {'shapeType': 'square', 'side': 2});
  });

  test('oneOf decodes an alias and preserves it when encoding', () {
    final shape = AliasedShape.fromJson(const {'shapeType': 'box', 'side': 2});

    expect(shape, isA<AliasedShapeAliasedSquare>());
    expect(shape.toJson(), {'shapeType': 'box', 'side': 2});
  });

  test('oneOf decodes an alias from simple encoding', () {
    final shape = AliasedShape.fromSimple(
      'shapeType=box,side=2',
      explode: true,
    );

    expect(shape, isA<AliasedShapeAliasedSquare>());
    expect(shape.toJson(), {'shapeType': 'box', 'side': 2});
  });

  test('oneOf decodes an alias from a header', () {
    final shape = AliasedShape.fromSimple(
      'shapeType=box,side=2',
      explode: true,
      isHeader: true,
    );

    expect(shape, isA<AliasedShapeAliasedSquare>());
    expect(shape.toJson(), {'shapeType': 'box', 'side': 2});
  });

  test('oneOf decodes an alias from form encoding', () {
    final shape = AliasedShape.fromForm('shapeType=box&side=2', explode: true);

    expect(shape, isA<AliasedShapeAliasedSquare>());
    expect(shape.toJson(), {'shapeType': 'box', 'side': 2});
  });

  test('anyOf accepts the alias without changing trial decoding', () {
    final shape = AliasedShapeAnyOf.fromJson(const {
      'shapeType': 'box',
      'side': 2,
    });

    expect(shape.aliasedSquare, isNotNull);
    expect(shape.aliasedCircle, isNull);
    expect(shape.toJson(), {'shapeType': 'box', 'side': 2});
  });

  test('explicit alias overrides another variant schema name', () {
    final shape = CollidingShape.fromJson(const {
      'shapeType': 'AliasedCircle',
      'side': 2,
    });

    expect(shape, isA<CollidingShapeAliasedSquare>());
    expect(shape.toJson(), {'shapeType': 'AliasedCircle', 'side': 2});
  });

  test('explicit alias wins with reversed variant order', () {
    final shape = ReversedCollidingShape.fromJson(const {
      'shapeType': 'AliasedCircle',
      'side': 2,
    });

    expect(shape, isA<ReversedCollidingShapeAliasedSquare>());
    expect(shape.toJson(), {'shapeType': 'AliasedCircle', 'side': 2});
  });

  test('explicit alias overrides implicit lookup in simple encoding', () {
    final shape = CollidingShape.fromSimple(
      'shapeType=AliasedCircle,side=2',
      explode: true,
    );

    expect(shape, isA<CollidingShapeAliasedSquare>());
    expect(shape.toJson(), {'shapeType': 'AliasedCircle', 'side': 2});
  });

  test('explicit alias overrides implicit lookup in headers', () {
    final shape = CollidingShape.fromSimple(
      'shapeType=AliasedCircle,side=2',
      explode: true,
      isHeader: true,
    );

    expect(shape, isA<CollidingShapeAliasedSquare>());
    expect(shape.toJson(), {'shapeType': 'AliasedCircle', 'side': 2});
  });

  test('explicit alias overrides implicit lookup in form encoding', () {
    final shape = CollidingShape.fromForm(
      'shapeType=AliasedCircle&side=2',
      explode: true,
    );

    expect(shape, isA<CollidingShapeAliasedSquare>());
    expect(shape.toJson(), {'shapeType': 'AliasedCircle', 'side': 2});
  });

  test('variant without a discriminator mapping still uses trial decoding', () {
    final shape = CollidingShape.fromJson(const {
      'shapeType': 'circle',
      'radius': 3,
    });

    expect(shape, isA<CollidingShapeAliasedCircle>());
    expect(shape.toJson(), {'shapeType': 'circle', 'radius': 3});
  });
}
