import 'dart:convert';
import 'dart:typed_data';

import 'package:big_decimal/big_decimal.dart';
import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('encodes typed JSON values and preserves text and file parts', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    expect(
      await api.postJsonValues(
        body: JsonValuesForm(
          timestamp: DateTime.utc(2026, 9, 14, 1, 2, 3),
          amount: BigDecimal.parse('12.340'),
          link: Uri.parse('https://example.test/a?b=c'),
          count: 7,
          enabled: true,
          schedules: [
            {
              'dates': [DateTime.utc(2026, 9, 15), DateTime.utc(2026, 9, 16)],
            },
          ],
          plain: 'unquoted text',
          file: TonikFileBytes(Uint8List.fromList([0, 255, 128])),
        ),
      ),
      isTonikSuccess,
    );

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), [
      'timestamp',
      'amount',
      'link',
      'count',
      'enabled',
      'schedules',
      'plain',
      'file',
    ]);
    expect(
      jsonDecode(wire.single('timestamp').bodyText),
      '2026-09-14T01:02:03.000Z',
    );
    expect(jsonDecode(wire.single('amount').bodyText), '12.340');
    expect(
      jsonDecode(wire.single('link').bodyText),
      'https://example.test/a?b=c',
    );
    expect(jsonDecode(wire.single('count').bodyText), 7);
    expect(jsonDecode(wire.single('enabled').bodyText), isTrue);
    expect(jsonDecode(wire.single('schedules').bodyText), {
      'dates': ['2026-09-15T00:00:00.000Z', '2026-09-16T00:00:00.000Z'],
    });
    expect(
      wire.single('timestamp').contentType,
      startsWith('application/json'),
    );
    expect(wire.single('amount').contentType, startsWith('application/json'));
    expect(
      wire.single('schedules').contentType,
      startsWith('application/json'),
    );
    expect(wire.single('plain').bodyText, 'unquoted text');
    expect(wire.single('plain').contentType, startsWith('text/plain'));
    expect(wire.single('file').bodyBytes, [0, 255, 128]);
    expect(
      wire.single('file').contentType,
      startsWith('application/octet-stream'),
    );
  });

  test('encodes values in merged JSON maps', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final result = await api.postJsonMergedMaps(
      body: JsonMergedMapsForm(
        firstDates: FirstDates(dates: {'start': DateTime.utc(2026, 9, 14)}),
        secondDates: SecondDates(dates: {'end': DateTime.utc(2026, 9, 15)}),
      ),
    );
    final error = switch (result) {
      TonikError(:final error) => '$error',
      _ => null,
    };
    expect(result, isTonikSuccess, reason: error);

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['dates']);
    expect(wire.single('dates').contentType, startsWith('application/json'));
    expect(jsonDecode(wire.single('dates').bodyText), {
      'start': '2026-09-14T00:00:00.000Z',
      'end': '2026-09-15T00:00:00.000Z',
    });
  });
}
