import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

void main() {
  test('content-type parsing is backend-neutral', () async {
    final libraryUri = await Isolate.resolvePackageUri(
      Uri.parse('package:tonik_util/tonik_util.dart'),
    );
    final decoderSource = File.fromUri(
      libraryUri!.resolve('src/decoding/response_decoder.dart'),
    ).readAsStringSync();
    final pubspec = File.fromUri(libraryUri.resolve('../pubspec.yaml'))
        .readAsStringSync();
    final workspacePubspec = File.fromUri(
      libraryUri.resolve('../../../pubspec.yaml'),
    ).readAsStringSync();

    expect(
      decoderSource,
      contains("import 'package:http_parser/http_parser.dart';"),
    );
    expect(decoderSource, isNot(contains("import 'package:dio/")));
    expect(decoderSource, isNot(contains('DioMediaType')));
    expect(pubspec, contains('  http_parser: ^4.1.2'));
    expect(workspacePubspec, contains('  http_parser: ^4.1.2'));
  });
}
