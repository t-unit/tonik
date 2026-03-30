import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/content_type_resolver.dart';

void main() {
  final log = Logger('test');

  group('resolveContentType', () {
    test('resolves application/json with charset parameter', () {
      final result = resolveContentType(
        'application/json; charset=utf-8',
        contentTypes: {},
        log: log,
      );
      expect(result, core.ContentType.json);
    });

    test('resolves multipart/form-data with boundary parameter', () {
      final result = resolveContentType(
        'multipart/form-data; boundary=something',
        contentTypes: {},
        log: log,
      );
      expect(result, core.ContentType.multipart);
    });

    test('resolves application/x-www-form-urlencoded with parameter', () {
      final result = resolveContentType(
        'application/x-www-form-urlencoded; charset=utf-8',
        contentTypes: {},
        log: log,
      );
      expect(result, core.ContentType.form);
    });

    test('resolves text/plain with parameter', () {
      final result = resolveContentType(
        'text/plain; charset=us-ascii',
        contentTypes: {},
        log: log,
      );
      expect(result, core.ContentType.text);
    });

    test('config override matches when input has parameters', () {
      final result = resolveContentType(
        'application/vnd.custom+json; charset=utf-8',
        contentTypes: {
          'application/vnd.custom+json': core.ContentType.json,
        },
        log: log,
      );
      expect(result, core.ContentType.json);
    });

    test('config override matches when input has no parameters', () {
      final result = resolveContentType(
        'application/vnd.custom+json',
        contentTypes: {
          'application/vnd.custom+json': core.ContentType.json,
        },
        log: log,
      );
      expect(result, core.ContentType.json);
    });

    test('resolves plain media types without parameters', () {
      expect(
        resolveContentType('application/json', contentTypes: {}, log: log),
        core.ContentType.json,
      );
      expect(
        resolveContentType('text/plain', contentTypes: {}, log: log),
        core.ContentType.text,
      );
      expect(
        resolveContentType(
          'application/octet-stream',
          contentTypes: {},
          log: log,
        ),
        core.ContentType.bytes,
      );
    });
  });
}
