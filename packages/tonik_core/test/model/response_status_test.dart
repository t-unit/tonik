import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ResponseStatus.compareTo', () {
    const explicit = ExplicitResponseStatus(statusCode: 200);
    const range = RangeResponseStatus(min: 200, max: 299);
    const defaultStatus = DefaultResponseStatus();

    test('explicit sorts before range', () {
      expect(explicit.compareTo(range), lessThan(0));
      expect(range.compareTo(explicit), greaterThan(0));
    });

    test('range sorts before default', () {
      expect(range.compareTo(defaultStatus), lessThan(0));
      expect(defaultStatus.compareTo(range), greaterThan(0));
    });

    test('explicit sorts before default', () {
      expect(explicit.compareTo(defaultStatus), lessThan(0));
      expect(defaultStatus.compareTo(explicit), greaterThan(0));
    });

    test('same specificity class compares equal regardless of value', () {
      const otherExplicit = ExplicitResponseStatus(statusCode: 404);
      const otherRange = RangeResponseStatus(min: 400, max: 499);

      expect(explicit.compareTo(otherExplicit), 0);
      expect(range.compareTo(otherRange), 0);
      expect(defaultStatus.compareTo(const DefaultResponseStatus()), 0);
    });

    test('sorting a shuffled input yields explicit, then range, then '
        'default', () {
      final shuffled = <ResponseStatus>[defaultStatus, range, explicit];

      mergeSort(shuffled);

      expect(shuffled, [explicit, range, defaultStatus]);
    });
  });
}
