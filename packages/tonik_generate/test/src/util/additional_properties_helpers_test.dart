import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/additional_properties_helpers.dart';

void main() {
  late Context context;
  late NameManager nameManager;
  late DartEmitter emitter;

  setUp(() {
    context = Context.initial();
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('additionalPropertiesType', () {
    group('with useImmutableCollections: true', () {
      test('TypedAdditionalProperties returns IMap<String, T>', () {
        final ap = TypedAdditionalProperties(
          valueModel: IntegerModel(context: context),
        );

        final result = additionalPropertiesType(
          ap,
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
        expect(result.types.length, 2);
        expect(result.types.first.accept(emitter).toString(), 'String');
        expect(result.types.last.accept(emitter).toString(), 'int');
      });

      test(
        'UnrestrictedAdditionalProperties returns IMap<String, Object?>',
        () {
          const ap = UnrestrictedAdditionalProperties();

          final result = additionalPropertiesType(
            ap,
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
          expect(result.types.length, 2);
          expect(result.types.first.accept(emitter).toString(), 'String');
          expect(result.types.last.accept(emitter).toString(), 'Object?');
        },
      );
    });

    group('with useImmutableCollections: false (default)', () {
      test('TypedAdditionalProperties returns Map<String, T>', () {
        final ap = TypedAdditionalProperties(
          valueModel: IntegerModel(context: context),
        );

        final result = additionalPropertiesType(
          ap,
          nameManager,
          'package:example',
        );

        expect(result.symbol, 'Map');
        expect(result.url, 'dart:core');
        expect(result.types.length, 2);
        expect(result.types.first.accept(emitter).toString(), 'String');
        expect(result.types.last.accept(emitter).toString(), 'int');
      });

      test('UnrestrictedAdditionalProperties returns Map<String, Object?>', () {
        const ap = UnrestrictedAdditionalProperties();

        final result = additionalPropertiesType(
          ap,
          nameManager,
          'package:example',
        );

        expect(result.symbol, 'Map');
        expect(result.url, 'dart:core');
        expect(result.types.length, 2);
        expect(result.types.first.accept(emitter).toString(), 'String');
        expect(result.types.last.accept(emitter).toString(), 'Object?');
      });
    });
  });
}
