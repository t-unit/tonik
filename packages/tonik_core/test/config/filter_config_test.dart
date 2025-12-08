import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('FilterConfig', () {
    test('defaults to empty lists for all filters', () {
      const config = FilterConfig();

      expect(config.includeTags, isEmpty);
      expect(config.excludeTags, isEmpty);
      expect(config.excludeOperations, isEmpty);
      expect(config.excludeSchemas, isEmpty);
    });
  });
}
