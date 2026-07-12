import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/additional_properties_builders.dart';

void main() {
  late Context context;
  late NameManager nameManager;

  setUp(() {
    context = Context.initial();
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
  });

  group('apMapTypeReference', () {
    group('with useImmutableCollections: true', () {
      test('typed value model returns IMap<String, T>', () {
        final result = apMapTypeReference(
          IntegerModel(context: context),
          nameManager,
          'package:example',
          useImmutableCollections: true,
        );

        expect(result.symbol, 'IMap');
        expect(
          result.url,
          'package:fast_immutable_collections/'
          'fast_immutable_collections.dart',
        );
        expect(result.types.first.symbol, 'String');
        expect(result.types.last.symbol, 'int');
      });

      test('Any value model returns IMap<String, Object?>', () {
        final result = apMapTypeReference(
          AnyModel(context: context),
          nameManager,
          'package:example',
          useImmutableCollections: true,
        );

        expect(result.symbol, 'IMap');
        expect(result.types.last.symbol, 'Object?');
      });
    });

    group('with useImmutableCollections: false (default)', () {
      test('typed value model returns Map<String, T>', () {
        final result = apMapTypeReference(
          IntegerModel(context: context),
          nameManager,
          'package:example',
        );

        expect(result.symbol, 'Map');
        expect(result.url, 'dart:core');
        expect(result.types.first.symbol, 'String');
        expect(result.types.last.symbol, 'int');
      });

      test('Any value model returns Map<String, Object?>', () {
        final result = apMapTypeReference(
          AnyModel(context: context),
          nameManager,
          'package:example',
        );

        expect(result.symbol, 'Map');
        expect(result.types.last.symbol, 'Object?');
      });
    });
  });
}
