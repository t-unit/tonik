import 'package:test/test.dart';
import 'package:tonik_core/src/transformer/config_transformer.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/enums', () {
    test(
      'applies enum value overrides and preserves non-overridden identity',
      () {
        final ctx = Context.initial();

        const active = EnumEntry<String>(value: 'active');

        const inactive = EnumEntry<String>(
          value: 'inactive',
        );

        final statusModel = EnumModel<String>(
          name: 'Status',
          values: {active, inactive},
          isNullable: false,
          context: ctx.push('Status'),
          isDeprecated: false,
        );

        final apiDocument = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {statusModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          nameOverrides: NameOverridesConfig(
            enums: {'Status.active': 'isActive'},
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(apiDocument, config);

        final transformedStatus = transformed.models
            .whereType<EnumModel<String>>()
            .firstWhere((m) => m.name == 'Status');

        expect(identical(transformedStatus, statusModel), isTrue);

        final transformedActive = transformedStatus.values.firstWhere(
          (e) => e.value == 'active',
        );
        final transformedInactive = transformedStatus.values.firstWhere(
          (e) => e.value == 'inactive',
        );

        expect(transformedActive.nameOverride, 'isActive');
        expect(identical(transformedActive, active), isFalse);

        expect(transformedInactive.nameOverride, isNull);
        expect(identical(transformedInactive, inactive), isTrue);
      },
    );
  });
}
