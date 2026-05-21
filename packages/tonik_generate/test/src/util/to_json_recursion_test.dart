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
    test('emits a local _encode helper that delegates to itself', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      tree.valueModel = tree;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final property = Property(
        name: 'body',
        model: tree,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      final built = buildToJsonPropertyExpression(
        'body',
        property,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      expect(built.inlineFunctions, hasLength(1));
      expect(built.inlineFunctions.single.name, '_encodeTree');

      final actual = emitMethod(built);
      final expected = format('''
        toJson() {
          late final Object? Function(Object?) _encodeTree;
          _encodeTree = (Object? raw) {
            final v = raw as Tree;
            return v.map((k, v) => MapEntry(k, _encodeTree(v)));
          };
          return _encodeTree(body);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });

  group('dedup on to_json side', () {
    test('two property uses share one _encode helper', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      tree.valueModel = tree;

      final ctx = InlineHelperContext(nameManager: nameManager);
      final property = Property(
        name: 'body',
        model: tree,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
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

  group('indirect to-JSON cycle', () {
    test('A ↔ B emits encode helpers for both', () {
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
      final property = Property(
        name: 'body',
        model: a,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      final built = buildToJsonPropertyExpression(
        'body',
        property,
        nameManager: nameManager,
        package: 'pkg',
        helperContext: ctx,
      );

      final actual = emitMethod(built);
      final expected = format('''
        toJson() {
          late final Object? Function(Object?) _encodeB;
          late final Object? Function(Object?) _encodeA;
          _encodeB = (Object? raw) {
            final v = raw as B;
            return v.map((k, v) => MapEntry(k, _encodeA(v)));
          };
          _encodeA = (Object? raw) {
            final v = raw as A;
            return v.map((k, v) => MapEntry(k, _encodeB(v)));
          };
          return _encodeA(body);
        }
      ''');

      expect(collapseWhitespace(actual), collapseWhitespace(expected));
    });
  });
}
