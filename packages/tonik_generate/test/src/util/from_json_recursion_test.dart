import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';

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
        ..name = 'fromJson'
        ..lambda = false
        ..body = Block.of([
          ...spliceInlineHelpers(built.inlineFunctions),
          built.unsafeRawBody.returned.statement,
        ]),
    );
    return format(method.accept(emitter).toString());
  }

  group('recursive named MapModel (Tree)', () {
    test(r'emits a local _$decode helper and calls it', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      tree.valueModel = tree;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final built = buildFromJsonValueExpression(
        'json',
        model: tree,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(built.inlineFunctions, hasLength(1));
      final helperName = built.inlineFunctions.single.name;
      expect(helperName, r'_$decodeTree');

      final actual = emitMethod(built);
      final expected = format(r'''
        fromJson() {
          late final Tree Function(Object?) _$decodeTree;
          _$decodeTree = (Object? v) =>
              v.decodeJsonMap((v) => _$decodeTree(v), context: r'Tree');
          return _$decodeTree(json);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });

  group('recursive named ListModel (Forest)', () {
    test(r'emits a single local _$decodeForest helper', () {
      final forest = ListModel(
        name: 'Forest',
        content: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      forest.content = forest;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final built = buildFromJsonValueExpression(
        'json',
        model: forest,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(built.inlineFunctions, hasLength(1));
      expect(built.inlineFunctions.single.name, r'_$decodeForest');
    });
  });

  group('dedup', () {
    test('one helper emitted when decoded twice in same method scope', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      );
      tree.valueModel = tree;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final first = buildFromJsonValueExpression(
        'a',
        model: tree,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );
      final second = buildFromJsonValueExpression(
        'b',
        model: tree,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(first.inlineFunctions, hasLength(1));
      // Second call must NOT re-emit the helper; it should just call it.
      expect(second.inlineFunctions, isEmpty);
    });
  });

  group('indirect cycle', () {
    test('A → Map<String,B> ↔ B → Map<String,A> emits helpers for both', () {
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
      final built = buildFromJsonValueExpression(
        'json',
        model: a,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      final actual = emitMethod(built);
      final expected = format(r'''
        fromJson() {
          late final B Function(Object?) _$decodeB;
          late final A Function(Object?) _$decodeA;
          _$decodeB = (Object? v) => v.decodeJsonMap((v) => _$decodeA(v), context: r'B');
          _$decodeA = (Object? v) => v.decodeJsonMap((v) => _$decodeB(v), context: r'A');
          return _$decodeA(json);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });

  group('nullable recursive typedef', () {
    test('emits a null-guarded call to the helper', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
        isNullable: true,
        examples: const [],
      );
      tree.valueModel = tree;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final built = buildFromJsonValueExpression(
        'json',
        model: tree,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
        isNullable: true,
      );

      final actual = emitMethod(built);
      final expected = format(r'''
        fromJson() {
          late final Tree Function(Object?) _$decodeTree;
          _$decodeTree = (Object? v) => v.decodeJsonMap(
              (v) => v == null ? null : _$decodeTree(v), context: r'Tree');
          return json == null ? null : _$decodeTree(json);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });

  group('AliasModel chain recursion', () {
    test('Tree -> TreeAlias -> Tree still emits a single decode helper', () {
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
      );
      tree.valueModel = alias;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final built = buildFromJsonValueExpression(
        'json',
        model: tree,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(built.inlineFunctions, hasLength(1));
      expect(built.inlineFunctions.single.name, r'_$decodeTree');

      final actual = emitMethod(built);
      final expected = format(r'''
        fromJson() {
          late final Tree Function(Object?) _$decodeTree;
          _$decodeTree = (Object? v) =>
              v.decodeJsonMap((v) => _$decodeTree(v), context: r'Tree');
          return _$decodeTree(json);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });

  group('three-way indirect cycle', () {
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
      final built = buildFromJsonValueExpression(
        'json',
        model: a,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(
        built.inlineFunctions.map((h) => h.name).toList(),
        [r'_$decodeC', r'_$decodeB', r'_$decodeA'],
      );

      final actual = emitMethod(built);
      final expected = format(r'''
        fromJson() {
          late final C Function(Object?) _$decodeC;
          late final B Function(Object?) _$decodeB;
          late final A Function(Object?) _$decodeA;
          _$decodeC = (Object? v) => v.decodeJsonMap((v) => _$decodeA(v), context: r'C');
          _$decodeB = (Object? v) => v.decodeJsonMap((v) => _$decodeC(v), context: r'B');
          _$decodeA = (Object? v) => v.decodeJsonMap((v) => _$decodeB(v), context: r'A');
          return _$decodeA(json);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });
}
