import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('NameOverridesConfig', () {
    test('retains empty maps for all overrides', () {
      const config = NameOverridesConfig(
        schemas: {},
        properties: {},
        operations: {},
        parameters: {},
        enums: {},
        tags: {},
      );

      expect(config.schemas, isEmpty);
      expect(config.properties, isEmpty);
      expect(config.operations, isEmpty);
      expect(config.parameters, isEmpty);
      expect(config.enums, isEmpty);
      expect(config.tags, isEmpty);
    });
  });
}
