import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('common generators contain no backend branches or native imports', () {
    const commonFiles = [
      'generator.dart',
      'pubspec_generator.dart',
      'library_generator.dart',
      'api_client/api_client_generator.dart',
      'operation/operation_generator.dart',
      'operation/parse_generator.dart',
      'server/server_generator.dart',
      'transport/multipart_header_plan.dart',
      'transport/operation_request_plan.dart',
      'transport/operation_request_planner.dart',
      'util/response_type_generator.dart',
    ];

    for (final relativePath in commonFiles) {
      final file = File(
        path.join(Directory.current.path, 'lib', 'src', relativePath),
      );
      final source = file.readAsStringSync();

      expect(
        source,
        isNot(contains('TransportBackend.dio')),
        reason: relativePath,
      );
      expect(
        source,
        isNot(contains('TransportBackend.http')),
        reason: relativePath,
      );
      expect(source, isNot(contains('package:dio/')), reason: relativePath);
      expect(source, isNot(contains('package:http/')), reason: relativePath);
    }
  });
}
