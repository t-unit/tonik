import 'dart:convert';

import 'package:adversarial_strings_api/adversarial_strings_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('equivalent timestamp strings remain distinct enum members', () {
    final precise = DateTimeChoice.fromJson('2026-09-06T12:00:00.1000+02:00');
    final short = DateTimeChoice.fromJson('2026-09-06T12:00:00.100+02:00');

    expect(precise, DateTimeChoice.$toDateTime);
    expect(short, DateTimeChoice.$toDateTime2);
    expect(precise, isNot(short));
    expect(precise.toJson(), '2026-09-06T12:00:00.1000+02:00');
    expect(short.toJson(), '2026-09-06T12:00:00.100+02:00');
    expect(jsonEncode(precise), '"2026-09-06T12:00:00.1000+02:00"');
  });

  test('undeclared timestamp spellings are rejected', () {
    expect(
      () => DateTimeChoice.fromJson('2026-09-06T10:00:00.100Z'),
      throwsA(isA<DecodingException>()),
    );
    expect(
      () => DateTimeChoice.fromSimple(
        '2026-09-06T12:00:00.10000+02:00',
        explode: false,
      ),
      throwsA(isA<DecodingException>()),
    );
    expect(
      () => DateTimeChoice.fromForm(
        '2026-09-06T10%3A00%3A00.100Z',
        explode: false,
      ),
      throwsA(isA<DecodingException>()),
    );
  });

  test('toDateTime preserves the offset without changing serialization', () {
    final precise = DateTimeChoice.$toDateTime.toDateTime();
    final short = DateTimeChoice.$toDateTime2.toDateTime();

    expect(precise, isA<DateTime>());
    expect(precise.timeZoneOffset, const Duration(hours: 2));
    expect(precise.hour, 12);
    expect(
      precise.isAtSameMomentAs(DateTime.utc(2026, 9, 6, 10, 0, 0, 100)),
      isTrue,
    );
    expect(precise.isAtSameMomentAs(short), isTrue);
    expect(
      DateTimeChoice.$toDateTime.toJson(),
      '2026-09-06T12:00:00.1000+02:00',
    );
  });

  test('date-time precision loss does not affect the enum wire value', () {
    final value = DateTimeChoice.nanoseconds.toDateTime();

    expect(value.millisecond, 123);
    expect(value.microsecond, 456);
    expect(
      DateTimeChoice.nanoseconds.toJson(),
      '2026-09-06T12:00:00.123456789+02:00',
    );
  });

  test('simple and form decoding preserve exact enum membership', () {
    expect(
      DateTimeChoice.fromSimple(
        '2026-09-06T12:00:00.1000+02:00',
        explode: false,
      ),
      DateTimeChoice.$toDateTime,
    );
    expect(
      DateTimeChoice.fromForm(
        '2026-09-06T12%3A00%3A00.1000%2B02%3A00',
        explode: false,
      ),
      DateTimeChoice.$toDateTime,
    );
  });

  test('parameter encoders retain the literal timestamp', () {
    const value = DateTimeChoice.$toDateTime;

    expect(
      value.toSimple(explode: false, allowEmpty: true, literal: true),
      '2026-09-06T12:00:00.1000+02:00',
    );
    expect(
      value.toForm(
        'timestamp',
        explode: false,
        allowEmpty: true,
        useQueryComponent: true,
        textEncoding: utf8,
      ),
      [(name: 'timestamp', value: '2026-09-06T12%3A00%3A00.1000%2B02%3A00')],
    );
    expect(
      value.toLabel(explode: false, allowEmpty: true),
      '.2026-09-06T12%3A00%3A00.1000%2B02%3A00',
    );
    expect(
      value.toMatrix('timestamp', explode: false, allowEmpty: true),
      ';timestamp=2026-09-06T12%3A00%3A00.1000%2B02%3A00',
    );
    expect(
      value.uriEncode(allowEmpty: true, textEncoding: utf8),
      '2026-09-06T12%3A00%3A00.1000%2B02%3A00',
    );
  });

  test('references, inline nullable enums and defaults retain literals', () {
    final value = DateTimeEnvelope.fromJson(const {
      'timestamp': '2026-09-06T12:00:00.1000+02:00',
      'optional': '2026-09-06t10:00:00.1000z',
    });

    expect(value.timestamp, DateTimeChoice.$toDateTime);
    expect(value.defaulted?.toJson(), '2026-09-06T12:00:00.1000+02:00');
    expect(
      value.defaulted?.toDateTime().timeZoneOffset,
      const Duration(hours: 2),
    );
    expect(value.optional?.toDateTime().isUtc, isTrue);
    expect(value.toJson(), {
      'timestamp': '2026-09-06T12:00:00.1000+02:00',
      'defaulted': '2026-09-06T12:00:00.1000+02:00',
      'optional': '2026-09-06t10:00:00.1000z',
    });
  });

  test('nullable date-time enum accepts null', () {
    final value = DateTimeEnvelope.fromJson(const {
      'timestamp': '2026-09-06T12:00:00.100+02:00',
      'optional': null,
    });

    expect(value.optional, isNull);
    expect(value.toJson(), {
      'timestamp': '2026-09-06T12:00:00.100+02:00',
      'defaulted': '2026-09-06T12:00:00.1000+02:00',
      'optional': null,
    });
  });

  test('component defaults are inherited through references and aliases', () {
    final value = DateTimeDefaultEnvelope.fromJson(const <String, Object?>{});

    expect(value.timestamp, DateTimeChoice.$toDateTime);
    expect(value.aliased, DateTimeChoice.$toDateTime);
    expect(value.toJson(), {
      'timestamp': '2026-09-06T12:00:00.1000+02:00',
      'aliased': '2026-09-06T12:00:00.1000+02:00',
    });
  });

  test('unknown fallback cannot be converted or serialized', () {
    final value = EmptyDateTimeChoice.fromJson('2026-09-06T12:00:00Z');

    expect(value, EmptyDateTimeChoice.unknown);
    expect(value.toDateTime, throwsStateError);
    expect(value.toJson, throwsA(isA<EncodingException>()));
  });

  test('unparseable literal only fails when converted to DateTime', () {
    final value = InvalidDateTimeChoice.fromJson('not-a-date');

    expect(value.toDateTime, throwsA(isA<DecodingException>()));
    expect(value.toJson(), 'not-a-date');
  });
}
