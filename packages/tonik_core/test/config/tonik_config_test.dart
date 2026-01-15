import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('TonikConfig', () {
    test('defaults to empty nested configs', () {
      const config = TonikConfig();

      expect(config.nameOverrides, const NameOverridesConfig());
      expect(config.contentTypes, isEmpty);
      expect(config.contentMediaTypes, isEmpty);
      expect(config.filter, const FilterConfig());
      expect(config.deprecated, const DeprecatedConfig());
      expect(config.enums, const EnumConfig());
    });

    test('stores contentMediaTypes configuration', () {
      const config = TonikConfig(
        contentMediaTypes: {
          'image/png': SchemaContentType.binary,
          'text/csv': SchemaContentType.text,
        },
      );

      expect(config.contentMediaTypes, hasLength(2));
      expect(
        config.contentMediaTypes['image/png'],
        SchemaContentType.binary,
      );
      expect(
        config.contentMediaTypes['text/csv'],
        SchemaContentType.text,
      );
    });

    test('equality includes contentMediaTypes', () {
      const config1 = TonikConfig(
        contentMediaTypes: {'image/png': SchemaContentType.binary},
      );
      const config2 = TonikConfig(
        contentMediaTypes: {'image/png': SchemaContentType.binary},
      );
      const config3 = TonikConfig(
        contentMediaTypes: {'image/png': SchemaContentType.text},
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });

  group('SchemaContentType', () {
    test('has binary and text values', () {
      expect(SchemaContentType.values, contains(SchemaContentType.binary));
      expect(SchemaContentType.values, contains(SchemaContentType.text));
    });
  });
}
