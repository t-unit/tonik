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

    test('resolves +json structured syntax suffix types to json '
        'without warning', () {
      final records = <LogRecord>[];
      final sub = log.onRecord.listen(records.add);
      addTearDown(sub.cancel);

      for (final mediaType in [
        'application/vnd.api+json',
        'application/ld+json',
        'application/problem+json',
        'application/vnd.custom+json',
        'image/whatever+json',
      ]) {
        expect(
          resolveContentType(mediaType, contentTypes: {}, log: log),
          core.ContentType.json,
          reason: mediaType,
        );
      }

      expect(records, isEmpty);
    });

    test('resolves +json suffix with parameters stripped', () {
      expect(
        resolveContentType(
          'application/vnd.api+json; charset=utf-8',
          contentTypes: {},
          log: log,
        ),
        core.ContentType.json,
      );
    });

    test('resolves +json suffix case-insensitively', () {
      expect(
        resolveContentType(
          'APPLICATION/VND.API+JSON',
          contentTypes: {},
          log: log,
        ),
        core.ContentType.json,
      );
    });

    test('config override takes precedence over +json suffix rule', () {
      expect(
        resolveContentType(
          'application/vnd.api+json',
          contentTypes: {'application/vnd.api+json': core.ContentType.bytes},
          log: log,
        ),
        core.ContentType.bytes,
      );
    });

    test('exact-match types are unchanged', () {
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
      expect(
        resolveContentType(
          'application/x-www-form-urlencoded',
          contentTypes: {},
          log: log,
        ),
        core.ContentType.form,
      );
      expect(
        resolveContentType('multipart/form-data', contentTypes: {}, log: log),
        core.ContentType.multipart,
      );
    });

    test('suffixes other than +json default to bytes with warning', () {
      final records = <LogRecord>[];
      final sub = log.onRecord.listen(records.add);
      addTearDown(sub.cancel);

      for (final mediaType in [
        'application/foo+xml',
        'application/foo+cbor',
      ]) {
        expect(
          resolveContentType(mediaType, contentTypes: {}, log: log),
          core.ContentType.bytes,
          reason: mediaType,
        );
      }

      expect(records.length, 2);
      expect(
        records.every((r) => r.message.contains('Unknown content type')),
        isTrue,
      );
    });

    test('unknown non-suffixed types default to bytes with warning', () {
      final records = <LogRecord>[];
      final sub = log.onRecord.listen(records.add);
      addTearDown(sub.cancel);

      expect(
        resolveContentType('application/whatever', contentTypes: {}, log: log),
        core.ContentType.bytes,
      );
      expect(records.length, 1);
      expect(records.single.message.contains('Unknown content type'), isTrue);
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
