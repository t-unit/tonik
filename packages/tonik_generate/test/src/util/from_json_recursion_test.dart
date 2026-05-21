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
    test('emits a local _decode helper and calls it', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
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
      expect(helperName, '_decodeTree');

      final actual = emitMethod(built);
      final expected = format('''
        fromJson() {
          late final Tree Function(Object?) _decodeTree;
          _decodeTree = (Object? v) =>
              v.decodeJsonMap((v) => _decodeTree(v), context: r'Tree');
          return _decodeTree(json);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });

  group('recursive named ListModel (Forest)', () {
    test('emits a single local _decodeForest helper', () {
      final forest = ListModel(
        name: 'Forest',
        content: AnyModel(context: context),
        context: context,
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
      expect(built.inlineFunctions.single.name, '_decodeForest');
    });
  });

  group('dedup', () {
    test('one helper emitted when decoded twice in same method scope', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
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
      );
      final b = MapModel(
        name: 'B',
        valueModel: AnyModel(context: context),
        context: context,
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
      final expected = format('''
        fromJson() {
          late final B Function(Object?) _decodeB;
          late final A Function(Object?) _decodeA;
          _decodeB = (Object? v) => v.decodeJsonMap((v) => _decodeA(v), context: r'B');
          _decodeA = (Object? v) => v.decodeJsonMap((v) => _decodeB(v), context: r'A');
          return _decodeA(json);
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
      final expected = format('''
        fromJson() {
          late final Tree Function(Object?) _decodeTree;
          _decodeTree = (Object? v) => v.decodeJsonMap(
              (v) => v == null ? null : _decodeTree(v), context: r'Tree');
          return json == null ? null : _decodeTree(json);
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
      );
      final alias = AliasModel(
        name: 'TreeAlias',
        model: tree,
        context: context,
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
      expect(built.inlineFunctions.single.name, '_decodeTree');

      final actual = emitMethod(built);
      final expected = format('''
        fromJson() {
          late final Tree Function(Object?) _decodeTree;
          _decodeTree = (Object? v) =>
              v.decodeJsonMap((v) => _decodeTree(v), context: r'Tree');
          return _decodeTree(json);
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
      );
      final b = MapModel(
        name: 'B',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final c = MapModel(
        name: 'C',
        valueModel: AnyModel(context: context),
        context: context,
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
        ['_decodeC', '_decodeB', '_decodeA'],
      );

      final actual = emitMethod(built);
      final expected = format('''
        fromJson() {
          late final C Function(Object?) _decodeC;
          late final B Function(Object?) _decodeB;
          late final A Function(Object?) _decodeA;
          _decodeC = (Object? v) => v.decodeJsonMap((v) => _decodeA(v), context: r'C');
          _decodeB = (Object? v) => v.decodeJsonMap((v) => _decodeC(v), context: r'B');
          _decodeA = (Object? v) => v.decodeJsonMap((v) => _decodeB(v), context: r'A');
          return _decodeA(json);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });

  group('naming collision', () {
    test('reserved scope names force a numeric suffix', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      tree.valueModel = tree;

      final ctx = InlineHelperContext(
        nameManager: nameManager,
        reservedNames: {'_decodeTree'},
      );
      final built = buildFromJsonValueExpression(
        'json',
        model: tree,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(built.inlineFunctions.single.name, '_decodeTree2');
    });
  });
}
