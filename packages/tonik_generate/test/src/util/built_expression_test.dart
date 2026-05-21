import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/built_expression.dart';

void main() {
  InlineHelper sampleHelper(String name) => InlineHelper(
    name: name,
    forwardDeclaration:
        Code('late final Object? Function(Object?) $name;'),
    assignment: Code('$name = (v) => v;'),
  );

  group('BuiltExpression', () {
    test('simple constructor leaves inlineFunctions empty', () {
      final built = BuiltExpression.simple(refer('x'));
      expect(built.inlineFunctions, isEmpty);
      expect(built.expression, refer('x'));
    });

    test('accept forwards to body when no helpers are present', () {
      final built = BuiltExpression.simple(refer('x'));
      final emitter = DartEmitter();
      expect(built.accept(emitter).toString(), 'x');
    });

    test('accept throws when helpers would be dropped', () {
      final helper = sampleHelper('_decodeTree');
      final built = BuiltExpression(
        body: refer('x'),
        inlineFunctions: [helper],
      );
      expect(() => built.accept(DartEmitter()), throwsStateError);
    });

    test('code throws when helpers would be dropped', () {
      final helper = sampleHelper('_decodeTree');
      final built = BuiltExpression(
        body: refer('x'),
        inlineFunctions: [helper],
      );
      expect(() => built.code, throwsStateError);
    });

    test('statement throws when helpers would be dropped', () {
      final helper = sampleHelper('_decodeTree');
      final built = BuiltExpression(
        body: refer('x'),
        inlineFunctions: [helper],
      );
      expect(() => built.statement, throwsStateError);
    });

    test('expression throws when helpers would be dropped', () {
      final helper = sampleHelper('_decodeTree');
      final built = BuiltExpression(
        body: refer('x'),
        inlineFunctions: [helper],
      );
      expect(() => built.expression, throwsStateError);
    });

    test('code forwards when no helpers are present', () {
      final built = BuiltExpression.simple(refer('value'));
      final emitter = DartEmitter();
      expect(built.code.accept(emitter).toString(), 'value');
    });

    test('unsafeRawBody returns the raw expression even with helpers', () {
      final helper = sampleHelper('_decodeTree');
      final built = BuiltExpression(
        body: refer('x'),
        inlineFunctions: [helper],
      );
      final emitter = DartEmitter();
      expect(built.unsafeRawBody.accept(emitter).toString(), 'x');
    });

    test('unsafeRawBody returns the inner expression without helpers', () {
      final built = BuiltExpression.simple(refer('value'));
      expect(built.unsafeRawBody, refer('value'));
    });

    test('inlineFunctions list is unmodifiable', () {
      final helper = sampleHelper('_decodeTree');
      final built = BuiltExpression(
        body: refer('x'),
        inlineFunctions: [helper],
      );
      expect(() => built.inlineFunctions.add(helper), throwsUnsupportedError);
    });
  });

  group('dedupHelpers', () {
    test('preserves first occurrence and drops later duplicates by name', () {
      final first = sampleHelper('_decodeTree');
      final second = sampleHelper('_decodeTree');
      final third = sampleHelper('_decodeForest');

      final out = dedupHelpers([first, second, third]);

      expect(out.length, 2);
      expect(out[0].name, '_decodeTree');
      expect(out[0].forwardDeclaration, same(first.forwardDeclaration));
      expect(out[1].name, '_decodeForest');
    });

    test('returns empty list for empty input', () {
      expect(dedupHelpers(const []), isEmpty);
    });
  });

  group('spliceInlineHelpers', () {
    test('emits all forward declarations before any assignment', () {
      final a = sampleHelper('_decodeA');
      final b = sampleHelper('_decodeB');

      final spliced = spliceInlineHelpers([a, b]);

      expect(spliced, hasLength(4));
      expect(spliced[0], same(a.forwardDeclaration));
      expect(spliced[1], same(b.forwardDeclaration));
      expect(spliced[2], same(a.assignment));
      expect(spliced[3], same(b.assignment));
    });

    test('deduplicates by name before splicing', () {
      final a1 = sampleHelper('_decodeA');
      final a2 = sampleHelper('_decodeA');

      final spliced = spliceInlineHelpers([a1, a2]);

      expect(spliced, hasLength(2));
      expect(spliced[0], same(a1.forwardDeclaration));
      expect(spliced[1], same(a1.assignment));
    });
  });

  group('collectInlineFunctions', () {
    test('flattens helpers across multiple BuiltExpressions, deduping', () {
      final first = sampleHelper('_decodeTree');
      final second = sampleHelper('_decodeForest');
      final third = sampleHelper('_decodeTree');

      final a = BuiltExpression(
        body: refer('x'),
        inlineFunctions: [first],
      );
      final b = BuiltExpression(
        body: refer('y'),
        inlineFunctions: [second, third],
      );

      final combined = collectInlineFunctions([a, b]);

      expect(combined.length, 2);
      expect(combined.map((h) => h.name), ['_decodeTree', '_decodeForest']);
    });
  });

  group('BuiltStatements', () {
    test('simple constructor leaves inlineFunctions empty', () {
      const statements = [Code('x;')];
      const built = BuiltStatements.simple(statements);
      expect(built.inlineFunctions, isEmpty);
      expect(built.statements, statements);
    });

    test('statements throws when helpers would be dropped', () {
      final helper = sampleHelper('_decodeTree');
      final built = BuiltStatements(
        statements: const [Code('x;')],
        inlineFunctions: [helper],
      );
      expect(() => built.statements, throwsStateError);
    });

    test('unsafeRawStatements returns statements even with helpers', () {
      final helper = sampleHelper('_decodeTree');
      const statements = [Code('x;')];
      final built = BuiltStatements(
        statements: statements,
        inlineFunctions: [helper],
      );
      expect(built.unsafeRawStatements, statements);
    });

    test('unsafeRawStatements returns statements without helpers', () {
      const statements = [Code('x;')];
      const built = BuiltStatements.simple(statements);
      expect(built.unsafeRawStatements, same(statements));
    });

    test('inlineFunctions list is unmodifiable', () {
      final helper = sampleHelper('_decodeTree');
      final built = BuiltStatements(
        statements: const [Code('x;')],
        inlineFunctions: [helper],
      );
      expect(() => built.inlineFunctions.add(helper), throwsUnsupportedError);
    });
  });
}
