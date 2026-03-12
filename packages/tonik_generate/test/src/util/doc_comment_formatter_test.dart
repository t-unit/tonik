import 'package:test/test.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';

void main() {
  group('doc comment formatter', () {
    test('formats a single line string', () {
      final result = formatDocComment('This is a doc comment');

      expect(result, isNotEmpty);
      expect(result.length, 1);
      expect(result.first, '/// This is a doc comment');
    });

    test('formats a multiline string', () {
      final result = formatDocComment(
        'This is a multiline\ndoc comment\nwith three lines',
      );

      expect(result, isNotEmpty);
      expect(result.length, 3);
      expect(result[0], '/// This is a multiline');
      expect(result[1], '/// doc comment');
      expect(result[2], '/// with three lines');
    });

    test('returns empty list for null string', () {
      final result = formatDocComment(null);

      expect(result, isEmpty);
    });

    test('returns empty list for empty string', () {
      final result = formatDocComment('');

      expect(result, isEmpty);
    });

    test('formats a list of strings', () {
      final result = formatDocComments([
        'First line',
        'Second line',
        null,
        '',
        'Last line',
      ]);

      expect(result, isNotEmpty);
      expect(result.length, 3);
      expect(result[0], '/// First line');
      expect(result[1], '/// Second line');
      expect(result[2], '/// Last line');
    });

    test('returns empty list for null list', () {
      final result = formatDocComments(null);

      expect(result, isEmpty);
    });

    test('returns empty list for empty list', () {
      final result = formatDocComments([]);

      expect(result, isEmpty);
    });

    test('returns empty list for list of nulls and empty strings', () {
      final result = formatDocComments([null, '', null]);

      expect(result, isEmpty);
    });

    test('handles multiline strings in list', () {
      final result = formatDocComments([
        'First\nMultiline',
        'Second',
      ]);

      expect(result, isNotEmpty);
      expect(result.length, 3);
      expect(result[0], '/// First');
      expect(result[1], '/// Multiline');
      expect(result[2], '/// Second');
    });
  });

  group('formatDocCommentWithPrefix', () {
    test('formats single line with prefix', () {
      final result = formatDocCommentWithPrefix(
        '[paramName] ',
        'A description',
      );

      expect(result, ['/// [paramName] A description']);
    });

    test('formats multi-line text with prefix on first line only', () {
      final result = formatDocCommentWithPrefix(
        '[sort] ',
        'Sort property.\n`updated` means the alert\'s state changed.',
      );

      expect(result, [
        '/// [sort] Sort property.',
        "/// `updated` means the alert's state changed.",
      ]);
    });

    test('handles three lines', () {
      final result = formatDocCommentWithPrefix(
        '- API Key (header): ',
        'Line one\nLine two\nLine three',
      );

      expect(result, [
        '/// - API Key (header): Line one',
        '/// Line two',
        '/// Line three',
      ]);
    });

    test('returns empty list for null text', () {
      final result = formatDocCommentWithPrefix('[param] ', null);

      expect(result, isEmpty);
    });

    test('returns empty list for empty text', () {
      final result = formatDocCommentWithPrefix('[param] ', '');

      expect(result, isEmpty);
    });

    test('handles text with empty continuation lines', () {
      final result = formatDocCommentWithPrefix(
        '[param] ',
        'First line\n\nThird line',
      );

      expect(result, [
        '/// [param] First line',
        '/// ',
        '/// Third line',
      ]);
    });
  });
}
