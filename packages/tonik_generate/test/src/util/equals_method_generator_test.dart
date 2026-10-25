import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';

void main() {
  late DartEmitter emitter;
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  String formatMethod(Method method) {
    final clazz = Class(
      (b) => b
        ..name = 'Temp'
        ..methods.add(method),
    );
    final library = Library((b) => b..body.add(clazz));
    final code = library.accept(emitter).toString();
    return format(code);
  }

  test('free-form values use deep equality in both collection modes', () {
    final model = AnyModel(context: Context.initial());

    expect(
      usesDeepCollectionEquality(model, useImmutableCollections: false),
      isTrue,
    );
    expect(
      usesDeepCollectionEquality(model, useImmutableCollections: true),
      isTrue,
    );
  });

  test('free-form aliases use deep equality with immutable collections', () {
    final context = Context.initial();
    final model = AliasModel(
      model: AnyModel(context: context),
      context: context,
      examples: const [],
      defaultValue: null,
      name: 'FreeformAlias',
      nameOverride: null,
      description: null,
      isDeprecated: false,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );

    expect(
      usesDeepCollectionEquality(model, useImmutableCollections: false),
      isTrue,
    );
    expect(
      usesDeepCollectionEquality(model, useImmutableCollections: true),
      isTrue,
    );
  });

  test('typed lists retain their existing collection-mode equality policy', () {
    final context = Context.initial();
    final model = ListModel(
      content: StringModel(context: context),
      context: context,
      examples: const [],
      name: null,
      nameOverride: null,
      isNullable: false,
      isContentNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );

    expect(
      usesDeepCollectionEquality(model, useImmutableCollections: false),
      isTrue,
    );
    expect(
      usesDeepCollectionEquality(model, useImmutableCollections: true),
      isFalse,
    );
  });

  test('scalar models retain direct equality in both collection modes', () {
    final model = IntegerModel(context: Context.initial());

    expect(
      usesDeepCollectionEquality(model, useImmutableCollections: false),
      isFalse,
    );
    expect(
      usesDeepCollectionEquality(model, useImmutableCollections: true),
      isFalse,
    );
  });

  group('EqualsMethodGenerator', () {
    test('generates equals method for class without properties', () {
      final method = generateEqualsMethod(
        className: 'TestClass',
        properties: const [],
      );

      const expectedMethod = '''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is TestClass;
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates equals method for class with single primitive property',
      () {
        final method = generateEqualsMethod(
          className: 'TestClass',
          properties: [(normalizedName: 'value', hasCollectionValue: false)],
        );

        const expectedMethod = '''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is TestClass && other.value == this.value;
        }
      ''';

        expect(
          collapseWhitespace(formatMethod(method)),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates equals method for class with collection property', () {
      final method = generateEqualsMethod(
        className: 'TestClass',
        properties: [(normalizedName: 'values', hasCollectionValue: true)],
      );

      const expectedMethod = r'''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          const _$deepEquals = DeepCollectionEquality();
          return other is TestClass && _$deepEquals.equals(other.values, this.values);
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates equals method for class with mixed properties', () {
      final method = generateEqualsMethod(
        className: 'TestClass',
        properties: [
          (normalizedName: 'id', hasCollectionValue: false),
          (normalizedName: 'items', hasCollectionValue: true),
          (normalizedName: 'name', hasCollectionValue: false),
        ],
      );

      const expectedMethod = r'''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          const _$deepEquals = DeepCollectionEquality();
          return other is TestClass &&
            other.id == this.id &&
            _$deepEquals.equals(other.items, this.items) &&
            other.name == this.name;
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
