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

    test('two explicit statuses order by status code', () {
      const created = ExplicitResponseStatus(statusCode: 201);
      expect(explicit.compareTo(created), lessThan(0));
      expect(created.compareTo(explicit), greaterThan(0));
    });

    test('two ranges order by lower bound', () {
      const clientError = RangeResponseStatus(min: 400, max: 499);
      expect(range.compareTo(clientError), lessThan(0));
      expect(clientError.compareTo(range), greaterThan(0));
    });

    test('standard sort yields explicit, then range, then default, ordered by '
        'status value within each class', () {
      const created = ExplicitResponseStatus(statusCode: 201);
      const clientError = RangeResponseStatus(min: 400, max: 499);
      final statuses = <ResponseStatus>[
        defaultStatus,
        clientError,
        range,
        created,
        explicit,
      ]..sort();

      expect(statuses, [explicit, created, range, clientError, defaultStatus]);
    });
  });
}
