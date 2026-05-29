import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/example_doc_formatter.dart';

void main() {
  group('formatExamplesAsDocs', () {
    test('returns empty list when given no examples', () {
      expect(formatExamplesAsDocs(const []), isEmpty);
    });

    group('headings', () {
      test('renders bare Example heading when name/summary absent', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: null,
            value: 'hi',
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// ```',
          '/// hi',
          '/// ```',
        ]);
      });

      test('includes name in heading when set', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: 'admin',
            summary: null,
            description: null,
            value: 42,
          ),
        ]);

        expect(result, [
          '/// **Example** "admin":',
          '/// ```json',
          '/// 42',
          '/// ```',
        ]);
      });

      test('appends summary after em dash when set', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: 'admin',
            summary: 'an admin user',
            description: null,
            value: 1,
          ),
        ]);

        expect(result.first, '/// **Example** "admin" — an admin user:');
      });

      test('renders summary without name', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: 'happy path',
            description: null,
            value: 1,
          ),
        ]);

        expect(result.first, '/// **Example** — happy path:');
      });

      test('treats empty summary as absent', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: 'admin',
            summary: '',
            description: null,
            value: 1,
          ),
        ]);

        expect(result.first, '/// **Example** "admin":');
      });

      test('passes through markdown-special chars in name and summary', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: 'a "quoted" name',
            summary: 'has *stars* and `ticks`',
            description: null,
            value: 1,
          ),
        ]);

        expect(
          result.first,
          '/// **Example** "a "quoted" name" — has *stars* and `ticks`:',
        );
      });
    });

    group('description', () {
      test('renders description block between heading and code fence', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: 'A typical admin user.',
            value: 1,
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// A typical admin user.',
          '///',
          '/// ```json',
          '/// 1',
          '/// ```',
        ]);
      });

      test('prefixes each description line', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: 'line one\nline two',
            value: 1,
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// line one',
          '/// line two',
          '///',
          '/// ```json',
          '/// 1',
          '/// ```',
        ]);
      });

      test('treats empty description as absent', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: '',
            value: 1,
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// ```json',
          '/// 1',
          '/// ```',
        ]);
      });

      test('escapes a description line that opens a markdown fence', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: 'See:\n```json\n{"x":1}\n```',
            value: 1,
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// See:',
          r'/// \```json',
          '/// {"x":1}',
          r'/// \```',
          '///',
          '/// ```json',
          '/// 1',
          '/// ```',
        ]);
      });
    });

    group('value rendering', () {
      test('renders string value in an untagged fence', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: null,
            value: 'plain text',
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// ```',
          '/// plain text',
          '/// ```',
        ]);
      });

      test('renders multi-line string value with each line prefixed', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: null,
            value: 'first\nsecond',
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// ```',
          '/// first',
          '/// second',
          '/// ```',
        ]);
      });

      test('renders int value as JSON', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: null,
            value: 42,
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// ```json',
          '/// 42',
          '/// ```',
        ]);
      });

      test('renders bool value as JSON', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: null,
            value: true,
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// ```json',
          '/// true',
          '/// ```',
        ]);
      });

      test('renders list value as pretty JSON', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: null,
            value: [1, 2, 3],
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// ```json',
          '/// [',
          '///   1,',
          '///   2,',
          '///   3',
          '/// ]',
          '/// ```',
        ]);
      });

      test('renders map value as pretty JSON', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: null,
            value: {'id': 1, 'name': 'alice'},
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// ```json',
          '/// {',
          '///   "id": 1,',
          '///   "name": "alice"',
          '/// }',
          '/// ```',
        ]);
      });

      test(
        'renders explicit-null value as JSON null when heading is present',
        () {
          final result = formatExamplesAsDocs([
            const Example(
              name: 'absent',
              summary: null,
              description: null,
              value: null,
            ),
          ]);

          expect(result, [
            '/// **Example** "absent":',
            '/// ```json',
            '/// null',
            '/// ```',
          ]);
        },
      );

      test(
        'skips an example whose value is null and has no other metadata',
        () {
          final result = formatExamplesAsDocs([
            const Example(
              name: null,
              summary: null,
              description: null,
              value: null,
            ),
          ]);

          expect(result, isEmpty);
        },
      );
    });

    group('fence escaping', () {
      test('uses a longer fence when value contains a triple-backtick run', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: null,
            value: 'before ``` after',
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// ````',
          '/// before ``` after',
          '/// ````',
        ]);
      });

      test('uses a fence one longer than the longest backtick run', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: null,
            summary: null,
            description: null,
            value: 'a ```` b',
          ),
        ]);

        expect(result, [
          '/// **Example**:',
          '/// `````',
          '/// a ```` b',
          '/// `````',
        ]);
      });
    });

    group('multiple examples', () {
      test(
        'separates entries with a blank /// line and preserves source order',
        () {
          final result = formatExamplesAsDocs([
            const Example(
              name: 'a',
              summary: null,
              description: null,
              value: 1,
            ),
            const Example(
              name: 'b',
              summary: null,
              description: null,
              value: 2,
            ),
          ]);

          expect(result, [
            '/// **Example** "a":',
            '/// ```json',
            '/// 1',
            '/// ```',
            '///',
            '/// **Example** "b":',
            '/// ```json',
            '/// 2',
            '/// ```',
          ]);
        },
      );

      test('omits skipped null-only entries from the output', () {
        final result = formatExamplesAsDocs([
          const Example(
            name: 'kept',
            summary: null,
            description: null,
            value: 1,
          ),
          const Example(
            name: null,
            summary: null,
            description: null,
            value: null,
          ),
          const Example(
            name: 'also-kept',
            summary: null,
            description: null,
            value: 2,
          ),
        ]);

        expect(result, [
          '/// **Example** "kept":',
          '/// ```json',
          '/// 1',
          '/// ```',
          '///',
          '/// **Example** "also-kept":',
          '/// ```json',
          '/// 2',
          '/// ```',
        ]);
      });

      test(
        'returns empty list when every entry is skipped',
        () {
          final result = formatExamplesAsDocs([
            const Example(
              name: null,
              summary: null,
              description: null,
              value: null,
            ),
            const Example(
              name: null,
              summary: null,
              description: null,
              value: null,
            ),
          ]);

          expect(result, isEmpty);
        },
      );
    });
  });
}
