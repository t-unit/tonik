import 'package:test/test.dart';
import 'package:type_arrays_api/type_arrays_api.dart';

void main() {
  test('typeless enum scalars and permissive values round-trip', () {
    final values = TypelessValues.fromJson(const {
      'color': 'red',
      'inlineColor': 'green',
      'priority': 1,
      'inlinePriority': 2,
      'itemsOnly': 'not an array',
      'mixed': true,
      'date': '2024-01-01',
      'encoded': 'cmVk',
    });

    expect(values.color?.toJson(), 'red');
    expect(values.inlineColor?.toJson(), 'green');
    expect(values.priority?.toJson(), 1);
    expect(values.inlinePriority?.toJson(), 2);
    expect(values.itemsOnly, 'not an array');
    expect(values.mixed, true);
    expect(values.date?.toJson(), '2024-01-01');
    expect(values.encoded?.toJson(), 'cmVk');
    expect(values.toJson(), {
      'color': 'red',
      'inlineColor': 'green',
      'priority': 1,
      'inlinePriority': 2,
      'itemsOnly': 'not an array',
      'mixed': true,
      'date': '2024-01-01',
      'encoded': 'cmVk',
    });
  });

  test('typeless enum null values and items arrays round-trip', () {
    final values = TypelessValues.fromJson(const {
      'color': null,
      'inlineColor': null,
      'priority': null,
      'inlinePriority': null,
      'itemsOnly': [1, 2],
      'mixed': 1,
      'date': null,
      'encoded': null,
    });

    expect(values.color, isNull);
    expect(values.inlineColor, isNull);
    expect(values.priority, isNull);
    expect(values.inlinePriority, isNull);
    expect(values.itemsOnly, [1, 2]);
    expect(values.mixed, 1);
    expect(values.date, isNull);
    expect(values.encoded, isNull);
    expect(values.toJson(), {
      'color': null,
      'inlineColor': null,
      'priority': null,
      'inlinePriority': null,
      'itemsOnly': [1, 2],
      'mixed': 1,
      'date': null,
      'encoded': null,
    });
  });
}
