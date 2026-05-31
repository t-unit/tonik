import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';

void main() {
  late Context context;
  late NameManager nameManager;
  late DartEmitter emitter;
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    context = Context.initial();
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    emitter = DartEmitter();
  });

  String emitMethod(BuiltExpression built) {
    final method = Method(
      (b) => b
        ..name = 'toJson'
        ..lambda = false
        ..body = Block.of([
          ...spliceInlineHelpers(built.inlineFunctions),
          built.unsafeRawBody.returned.statement,
        ]),
    );
    return format(method.accept(emitter).toString());
  }

  group('recursive named MapModel (Tree)', () {
    test(r'emits a local _$encode helper that delegates to itself', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      tree.valueModel = tree;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final property = Property(
        name: 'body',
        model: tree,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final built = buildToJsonPropertyExpression(
        'body',
        property,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(built.inlineFunctions, hasLength(1));
      expect(built.inlineFunctions.single.name, r'_$encodeTree');

      final actual = emitMethod(built);
      final expected = format(r'''
        toJson() {
          late final Object? Function(Object?) _$encodeTree;
          _$encodeTree = (Object? raw) {
            if (raw is! Tree) {
              throw EncodingException('Cannot encode value as Tree; got: '
                  '${raw.runtimeType}');
            }
            final v = raw;
            return v.map((k, v) => MapEntry(k, _$encodeTree(v)));
          };
          return _$encodeTree(body);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });

    test(
      'encode helper carries contextClass.contextProperty in the message',
      () {
        final tree = MapModel(
          name: 'Tree',
          valueModel: AnyModel(context: context),
          context: context,
          examples: const [],
        );
        tree.valueModel = tree;

        final ctx = InlineHelperContext(nameManager: nameManager);
        final property = Property(
          name: 'subtree',
          model: tree,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        );
        final built = buildToJsonPropertyExpression(
          'subtree',
          property,
          nameManager: nameManager,
          package: 'pkg',
          helperContext: ctx,
          contextClass: 'Node',
          contextProperty: 'subtree',
        );

        final actual = emitMethod(built);
        final expected = format(r'''
          toJson() {
            late final Object? Function(Object?) _$encodeTree;
            _$encodeTree = (Object? raw) {
              if (raw is! Tree) {
                throw EncodingException(
                  'Cannot encode value as Tree (at \'Node.subtree\'); got: '
                  '${raw.runtimeType}',
                );
              }
              final v = raw;
              return v.map((k, v) => MapEntry(k, _$encodeTree(v)));
            };
            return _$encodeTree(subtree);
          }
        ''');

        expect(collapseWhitespace(actual), collapseWhitespace(expected));
      },
    );
  });

  group('nullable cycle', () {
    test('nullable recursive Tree wraps helper call in null-handling', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      tree.valueModel = tree;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final property = Property(
        name: 'subtree',
        model: tree,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final built = buildToJsonPropertyExpression(
        'subtree',
        property,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      final actual = emitMethod(built);
      final expected = format(r'''
        toJson() {
          late final Object? Function(Object?) _$encodeTree;
          _$encodeTree = (Object? raw) {
            if (raw is! Tree) {
              throw EncodingException('Cannot encode value as Tree; got: '
                  '${raw.runtimeType}');
            }
            final v = raw;
            return v.map((k, v) => MapEntry(k, _$encodeTree(v)));
          };
          return subtree == null ? null : _$encodeTree(subtree);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });

  group('dedup on to_json side', () {
    test(r'two property uses share one _$encode helper', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      tree.valueModel = tree;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final property = Property(
        name: 'body',
        model: tree,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );

      final first = buildToJsonPropertyExpression(
        'a',
        property,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );
      final second = buildToJsonPropertyExpression(
        'b',
        property,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(first.inlineFunctions, hasLength(1));
      expect(second.inlineFunctions, isEmpty);
    });
  });

  group('AliasModel chain recursion', () {
    test('Tree -> TreeAlias -> Tree still emits a single encode helper', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      final alias = AliasModel(
        name: 'TreeAlias',
        model: tree,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      tree.valueModel = alias;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final property = Property(
        name: 'body',
        model: tree,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final built = buildToJsonPropertyExpression(
        'body',
        property,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(built.inlineFunctions, hasLength(1));
      expect(built.inlineFunctions.single.name, r'_$encodeTree');

      final actual = emitMethod(built);
      final expected = format(r'''
        toJson() {
          late final Object? Function(Object?) _$encodeTree;
          _$encodeTree = (Object? raw) {
            if (raw is! Tree) {
              throw EncodingException('Cannot encode value as Tree; got: '
                  '${raw.runtimeType}');
            }
            final v = raw;
            return v.map((k, v) => MapEntry(k, _$encodeTree(v)));
          };
          return _$encodeTree(body);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });

  group('three-way indirect to-JSON cycle', () {
    test('A -> Map<String,B> -> Map<String,C> -> Map<String,A>', () {
      final a = MapModel(
        name: 'A',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      final b = MapModel(
        name: 'B',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      final c = MapModel(
        name: 'C',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      a.valueModel = b;
      b.valueModel = c;
      c.valueModel = a;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final property = Property(
        name: 'body',
        model: a,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final built = buildToJsonPropertyExpression(
        'body',
        property,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(
        built.inlineFunctions.map((h) => h.name).toList(),
        [r'_$encodeC', r'_$encodeB', r'_$encodeA'],
      );

      final actual = emitMethod(built);
      final expected = format(r'''
        toJson() {
          late final Object? Function(Object?) _$encodeC;
          late final Object? Function(Object?) _$encodeB;
          late final Object? Function(Object?) _$encodeA;
          _$encodeC = (Object? raw) {
            if (raw is! C) {
              throw EncodingException('Cannot encode value as C; got: '
                  '${raw.runtimeType}');
            }
            final v = raw;
            return v.map((k, v) => MapEntry(k, _$encodeA(v)));
          };
          _$encodeB = (Object? raw) {
            if (raw is! B) {
              throw EncodingException('Cannot encode value as B; got: '
                  '${raw.runtimeType}');
            }
            final v = raw;
            return v.map((k, v) => MapEntry(k, _$encodeC(v)));
          };
          _$encodeA = (Object? raw) {
            if (raw is! A) {
              throw EncodingException('Cannot encode value as A; got: '
                  '${raw.runtimeType}');
            }
            final v = raw;
            return v.map((k, v) => MapEntry(k, _$encodeB(v)));
          };
          return _$encodeA(body);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });

  group('indirect to-JSON cycle', () {
    test('A <-> B emits encode helpers for both', () {
      final a = MapModel(
        name: 'A',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      final b = MapModel(
        name: 'B',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      a.valueModel = b;
      b.valueModel = a;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final property = Property(
        name: 'body',
        model: a,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final built = buildToJsonPropertyExpression(
        'body',
        property,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      final actual = emitMethod(built);
      final expected = format(r'''
        toJson() {
          late final Object? Function(Object?) _$encodeB;
          late final Object? Function(Object?) _$encodeA;
          _$encodeB = (Object? raw) {
            if (raw is! B) {
              throw EncodingException('Cannot encode value as B; got: '
                  '${raw.runtimeType}');
            }
            final v = raw;
            return v.map((k, v) => MapEntry(k, _$encodeA(v)));
          };
          _$encodeA = (Object? raw) {
            if (raw is! A) {
              throw EncodingException('Cannot encode value as A; got: '
                  '${raw.runtimeType}');
            }
            final v = raw;
            return v.map((k, v) => MapEntry(k, _$encodeB(v)));
          };
          return _$encodeA(body);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });
}
