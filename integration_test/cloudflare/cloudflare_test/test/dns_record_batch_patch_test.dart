import 'package:cloudflare_api/cloudflare_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('DNS batch patch round-trips the record and its ID', () {
    final patch = DnsRecordsDnsRecordBatchPatch.fromJson(const {
      'id': '023e105f4ecef8ad9ca31a8372d0c353',
      'name': 'example.com',
      'type': 'A',
      'content': '192.0.2.1',
    });

    expect(
      patch.toJson(),
      allOf(
        containsPair('id', '023e105f4ecef8ad9ca31a8372d0c353'),
        containsPair('name', 'example.com'),
        containsPair('type', 'A'),
        containsPair('content', '192.0.2.1'),
      ),
    );
  });

  test('DNS batch patch requires the record ID', () {
    expect(
      () => DnsRecordsDnsRecordBatchPatch.fromJson(const {
        'name': 'example.com',
        'type': 'A',
        'content': '192.0.2.1',
      }),
      throwsA(isA<DecodingException>()),
    );
  });
}
